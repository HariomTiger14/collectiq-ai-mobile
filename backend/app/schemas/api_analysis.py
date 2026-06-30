from typing import Any

from pydantic import BaseModel, Field


class ApiAnalysisRequestMetadata(BaseModel):
    imagePath: str
    imageSource: str
    timestamp: str
    requestedCategory: str | None = None
    appVersion: str | None = None
    deviceMetadata: dict[str, str] = Field(default_factory=dict)


class ApiImagePayload(BaseModel):
    fileName: str
    mimeType: str
    sizeBytes: int
    imageSource: str
    localFilePath: str
    base64Image: str | None = None
    base64Preview: str | None = None


class ApiAnalyzeRequest(BaseModel):
    request: ApiAnalysisRequestMetadata
    image: ApiImagePayload


class ApiAlternativeMatchResponse(BaseModel):
    title: str
    category: str
    confidence: int
    reason: str


class ApiReviewResponse(BaseModel):
    primaryMatch: str
    confidenceExplanation: str
    detectionQuality: str
    reasoning: str


class ApiMarketCompResponse(BaseModel):
    source: str
    title: str
    soldPrice: int
    currency: str
    soldDate: str
    condition: str
    url: str | None = None


class ApiMarketSummaryResponse(BaseModel):
    averagePrice: int
    medianPrice: int
    lowPrice: int
    highPrice: int
    salesCount: int
    trendLabel: str
    confidence: int
    lastUpdated: str
    sources: list[str]
    comps: list[ApiMarketCompResponse] = Field(default_factory=list)


class ApiAnalyzeResponse(BaseModel):
    id: str
    itemName: str
    category: str
    estimatedValue: int
    lowEstimate: int
    highEstimate: int
    confidence: int
    condition: str
    marketTrend: str
    keyAttributes: dict[str, str]
    aiReview: ApiReviewResponse
    alternatives: list[ApiAlternativeMatchResponse]
    recommendation: str
    marketSummary: ApiMarketSummaryResponse
    comparableSales: list[ApiMarketCompResponse]
    imageUrl: str | None = None
    timestamp: str


class ApiAnalyzeErrorResponse(BaseModel):
    error: dict[str, Any]
