from pydantic import BaseModel


class AlternativeMatchResponse(BaseModel):
    title: str
    category: str
    confidence: int
    reason: str


class ScannerAnalysisResponse(BaseModel):
    success: bool
    filename: str
    imageUrl: str
    title: str
    category: str
    confidence: int
    estimatedValue: int
    condition: str
    recommendation: str
    description: str
    detectedObjects: list[str]
    aiProvider: str
    processingTimeMs: int
    primaryMatch: str
    alternativeMatches: list[AlternativeMatchResponse]
    confidenceExplanation: str
    detectionQuality: str
    aiReasoning: str
