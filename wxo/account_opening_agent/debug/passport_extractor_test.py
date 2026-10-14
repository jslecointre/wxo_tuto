"""Minimal image-extraction test: one docext node, two text fields, no other node.

Classic variant; passport_extractor_test_layout.py holds the layout variant.
"""

import sys
from pathlib import Path

from pydantic import BaseModel, Field

from ibm_watsonx_orchestrate.flow_builder.flows import END, START, Flow, flow
from ibm_watsonx_orchestrate.flow_builder.types import (
    DocExtConfigField,
    DocumentProcessingCommonInput,
)


# Full field set of the real workflow, to test it in isolation.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
from create_new_bank_account_flow import PassportFields  # noqa: E402


class MinimalPassportFields(BaseModel):
    given_name: DocExtConfigField = Field(
        default=DocExtConfigField(
            name="Given name",
            field_name="given_name",
            description="The given name(s) of the holder.",
        )
    )
    nationality: DocExtConfigField = Field(
        default=DocExtConfigField(
            name="Nationality",
            field_name="nationality",
            description="The holder's nationality.",
        )
    )


class ExtractedPassport(BaseModel):
    given_name: str = Field(default="", description="Extracted given name")
    nationality: str = Field(default="", description="Extracted nationality")
    surname: str = Field(default="", description="Extracted surname")
    passport_number: str = Field(default="", description="Extracted passport number")
    date_of_birth: str = Field(default="", description="Extracted date of birth")


def _build(
    aflow: Flow, method: str, fields: BaseModel | None = None, review: bool = False
) -> Flow:
    fields = fields or MinimalPassportFields()
    extract, _ = aflow.docext(
        name="extract",
        display_name=f"Extract ({method})",
        fields=fields,
        field_extraction_method=method,
        # Human-in-the-loop "Review document extraction" screen: fields below min_confidence are shown for review.
        enable_review=review,
        min_confidence=0.95 if review else 0,
        review_fields=list(type(fields).model_fields) if review else [],
    )
    extract.map_input(
        input_variable="document_ref", expression="flow.input.document_ref"
    )
    aflow.sequence(START, extract, END)
    aflow.map_output(
        output_variable="given_name",
        expression="flow['extract'].output.given_name",
        default_value="",
    )
    aflow.map_output(
        output_variable="nationality",
        expression="flow['extract'].output.nationality",
        default_value="",
    )
    if fields is not None:
        for name in ("surname", "passport_number", "date_of_birth"):
            aflow.map_output(
                output_variable=name,
                expression=f"str(flow['extract'].output.{name})",
                default_value="",
            )
    return aflow


@flow(
    name="passport_extractor_test_classic",
    display_name="Passport extractor test (classic)",
    description="Test: extracts the given name and nationality from an uploaded passport image (classic method).",
    input_schema=DocumentProcessingCommonInput,
    output_schema=ExtractedPassport,
)
def build_passport_extractor_test_classic(aflow: Flow) -> Flow:
    # Real workflow's fields, default model, only document_ref mapped, extraction review enabled.
    return _build(aflow, "classic", PassportFields(), review=True)
