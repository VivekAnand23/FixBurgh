# Society admin verification (draft, pending approval)

Burghood Phase 1. This is the wording the app and the privacy policy use
for checking that the person creating a society runs it. **Every block
below is a draft for Vivek's approval.** Change the text here and in the
places listed, then remove the "pending" markers.

| Where | File |
|---|---|
| Create a society, "Your documents" box | `lib/l10n/app_en.arb` key `verificationRequirements` (dev builds show a "Draft wording" chip next to it) |
| Find your society, "Create a society" card | `createSocietyNeeds` |
| Claim status screen | `claimFilesNote`, `claimStepReviewBody` |
| Privacy policy | `hosting/public/privacy.html`, the "Societies" and "Verifying society admins" sections and the retention line (marked PENDING APPROVAL) |
| Console reviewer note | `hosting/public/admin/index.html`, Claims section |

## What the applicant sees

> We need two documents.
> 1. A government photo ID: a driver's license, state ID or passport, with
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

## Open questions for approval

1. Is 30 days after the decision the right retention, or should rejected
   claims' files go sooner (for example 7 days)? It's one setting:
   `CLAIM_FILE_RETENTION_DAYS` in the functions' environment.
2. Should a property manager's claim also need a letter from the board, or
   is the management agreement enough?
3. Accept a passport card or military ID as photo ID?
