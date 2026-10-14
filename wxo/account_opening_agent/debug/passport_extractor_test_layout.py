"""Layout variant of the minimal image-extraction test (see passport_extractor_test.py)."""

from ibm_watsonx_orchestrate.flow_builder.flows import Flow, flow
from ibm_watsonx_orchestrate.flow_builder.types import DocumentProcessingCommonInput

from passport_extractor_test import ExtractedPassport, _build


@flow(
    name="passport_extractor_test_layout",
    display_name="Passport extractor test (layout)",
    description="Test: extracts the given name and nationality from an uploaded passport image (layout method).",
    input_schema=DocumentProcessingCommonInput,
    output_schema=ExtractedPassport,
)
def build_passport_extractor_test_layout(aflow: Flow) -> Flow:
    return _build(aflow, "layout")
