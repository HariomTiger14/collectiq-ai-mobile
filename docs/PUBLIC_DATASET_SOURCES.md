# Public Dataset Sources for CollectIQ AI Validation

Use this catalog as a starting point for safe validation data. Always review the
current dataset license before downloading or using images. Do not commit image
files to this repository.

| Source | Category | License / Usage Note | Download Method | Expected Metadata Fields | Login / Token |
| --- | --- | --- | --- | --- | --- |
| User-owned photo set | Any supported category | Safest option. You own the photos and can label them manually. | Local folder import with `scripts\import_validation_dataset.ps1`. | filename, name/title, category, brand, set/series, year, notes. | No |
| Kaggle datasets for trading cards or coins | Cards, coins, comics depending on dataset | Varies by dataset. Check Kaggle license and original source before use. | Download manually with Kaggle UI/CLI, then import the local folder. | Often filename, class/label, category, set, year. | Usually yes |
| Hugging Face dataset exports | General image classification datasets | Varies by dataset card. Prefer datasets with explicit open licenses. | Download/export manually, then import local CSV/JSON metadata. | image/file/path, label/class, category, metadata columns. | Sometimes |
| Roboflow Universe exports | Object detection/classification datasets | Varies. Check dataset page and export license. | Export manually, then import local images and metadata. | filename, class, split, labels, annotations. | Usually yes |
| Wikimedia Commons public-domain images | Coins, comics covers where allowed, memorabilia | Use only images with compatible licenses. Preserve attribution notes when required. | Download manually. Do not scrape bulk search results. | filename, title, category, license, source URL in notes. | No |
| Public-domain museum/archive images | Coins, memorabilia, historical objects | Usually public domain or institution-specific open license. Verify terms. | Download manually from official archive pages. | filename, item title, date/year, institution/source, license. | No |

## Importing a Dataset

Images remain local and are ignored by git. Metadata can be imported from CSV or
JSON:

```powershell
scripts\import_validation_dataset.ps1 `
  -ImageFolder C:\datasets\collectiq_safe_images `
  -Metadata C:\datasets\collectiq_safe_images\metadata.csv `
  -SourceName "User-owned validation set" `
  -License "user-owned" `
  -OutputManifest validation\manifests\generated_manifest.json
```

If you want to copy images into the local validation folder, use:

```powershell
scripts\import_validation_dataset.ps1 `
  -ImageFolder C:\datasets\collectiq_safe_images `
  -Metadata C:\datasets\collectiq_safe_images\metadata.json `
  -CopyImagesTo validation\images
```

`validation/images/**` is gitignored except `.gitkeep`, so copied images stay
local.

## Supported Metadata Names

The importer recognizes common column names:

- image: `filename`, `image`, `image_filename`, `file_name`, `filepath`,
  `file_path`, `path`
- name: `expected_name`, `name`, `title`, `item_name`, `label`, `class`,
  `card_name`, `coin_name`, `comic_title`
- category: `expected_category`, `category`, `type`, `collectible_type`
- brand: `expected_brand`, `brand`, `franchise`, `manufacturer`, `publisher`,
  `mint`
- set/series: `expected_set`, `set`, `set_name`, `series`, `collection`,
  `issue`
- year: `expected_year`, `year`, `release_year`, `date`, `issued`

Unknown fields are ignored. Add notes to the generated manifest if manual
cleanup is needed before validation.
