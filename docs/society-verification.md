# Society admin verification

Burghood Phase 1. The wording the app and the privacy policy use for
checking that the person creating a society runs it. Approved by Vivek on
24 October 2026. Where it appears:

| Where | File |
|---|---|
| Create a society, "Your documents" box | `lib/l10n/app_en.arb` key `verificationRequirements` |
| Find your society, "Create a society" card | `createSocietyNeeds` |
| Claim status screen | `claimFilesNote`, `claimStepReviewBody` |
| Privacy policy | `hosting/public/privacy.html`, the "Societies" and "Verifying society admins" sections and the retention line |
| Console reviewer note | `hosting/public/admin/index.html`, Claims section |

## What the applicant sees

> We need two documents.
> 1. A government photo ID: a driver's license, state ID, passport or
>    passport card, or military ID, with
>    your name and photo easy to read.
> 2. Proof of office that names you and the society: a board resolution,
>    election minutes, or a management agreement.
>
> Photos or PDFs, up to 5 MB each. The name on both must match.

Confirmation checkbox:

> I hold this position in the society, and these documents are genuine.

After sending:

> Your ID and proof of office are seen only by Burghood staff and are
> deleted 30 days after the decision.

Positions offered: President, Secretary, Board member, Manager.

## What the reviewer checks (console)

> Check that the photo ID and proof of office name the same person, and
> that the proof names the society. Target: decide within 2 working days.

Suggested rejection reasons (typed by the reviewer, shown to the applicant):

- "The name on your ID doesn't match the name on the proof of office."
- "The proof of office doesn't name the society or your position."
- "We couldn't read the document. Please upload a clearer photo or a PDF."
- "A verified society already exists at this address. Ask its admin to add you."

## Privacy policy addition (summary)

- Societies: members see your account name, unit and role; notices and
  documents are for approved members only; only HOA links are stored.
- Verification: the two documents are collected only to verify the
  claim, opened only by platform admins (each view is logged), never shown
  to the society or anyone else, and deleted 30 days after the decision.
  The claim record (society, applicant name, email, position, decision and
  reviewer) is kept while the society exists. Deleting your account deletes
  your claims and any remaining files.

## Decisions (24 Oct 2026)

1. **Retention:** 30 days after the decision for both approved and rejected
   claims, so a rejected applicant can ask what was wrong while the files
   still exist. One setting, `CLAIM_FILE_RETENTION_DAYS`, if this changes.
2. **Property managers:** the management agreement naming them and the
   society is enough; no separate board letter.
3. **Photo ID:** a passport card or military ID is accepted as well as a
   driver's license, state ID or passport.
