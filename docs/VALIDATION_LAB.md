# CollectIQ AI Validation Lab

The validation lab tests the backend analysis contract against public/open
datasets or user-provided local images. Automated runs stay in mock/default mode
unless you manually enable real backend providers.

## Safety Rules

- Do not scrape Google, eBay, marketplace, or seller listing images.
- Do not commit copyrighted dataset images unless the dataset license allows it.
- Prefer user-owned images, public-domain images, or datasets with explicit
  open licenses.
- If Kaggle, Hugging Face, or Roboflow requires a login or token, download the
  dataset manually and point the lab at the local export.
- Do not call paid OpenAI/eBay providers in automated tests.
- Keep provider API keys in backend `.env` only.

## Folder Structure

```text
validation/
  images/
  manifests/
  reports/
```

`validation/images/` is for local test images. `validation/manifests/` contains
ground-truth metadata. `validation/reports/` contains generated markdown and CSV
reports.

## Manifest Fields

```csv
filename,expected_name,expected_category,expected_brand,expected_set,expected_year,expected_price_min,expected_price_max,source,license,notes
```

JSON manifests use the same field names. Price fields are optional. Leave any
unknown field blank instead of guessing.

## Supported Sources

The preparer supports local paths only:

- user-provided image folder;
- Kaggle dataset folder already downloaded locally;
- Hugging Face dataset export already downloaded locally;
- CSV/JSON manifest with expected labels.

No credentials are stored by the repo or scripts.

## Prepare a Dataset

From the repository root:

```powershell
scripts\run_validation_lab.ps1 `
  -UserImageFolder C:\path\to\owned-or-open-images `
  -ManifestPath validation\manifests\my_manifest.json `
  -PrepareOnly
```

If you already have a labeled manifest, place images in `validation/images/` and
save the manifest under `validation/manifests/`.

## Run the Lab

Start the backend in mock mode:

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
$env:AI_PROVIDER="mock"
$env:PRICING_PROVIDER="mock"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Then run:

```powershell
scripts\run_validation_lab.ps1 `
  -ManifestPath validation\manifests\my_manifest.json `
  -ImageDir validation\images `
  -Endpoint http://127.0.0.1:8000/api/analyze
```

For a safe placeholder report that does not require images:

```powershell
scripts\run_validation_lab.ps1 -DryRun
```

Reports are written to:

```text
validation/reports/latest_validation_report.md
validation/reports/latest_validation_results.csv
```

## Metrics

The lab records:

- category accuracy;
- name keyword match accuracy;
- set and year match where ground truth exists;
- price in expected range where a range exists;
- average latency;
- low-confidence count;
- failed image count;
- fallback reason.

## Real Provider Validation

Real OpenAI/eBay validation is manual/local only. Enable providers in
`backend/.env`, start the backend, run the same lab command, and record notes in
the generated report. Watch provider cost and quota carefully.
