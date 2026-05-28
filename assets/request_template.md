# Asset Request Template

## Request Information

### 1. Request Details
- **Request ID:** `[AUTO-GENERATED]`
- **Request Date:** `[YYYY-MM-DD]`
- **Requester Name:** `[Full Name]`
- **Requester Email:** `[Email Address]`
- **Department/Team:** `[Department Name]`
- **Request Priority:** `[HIGH / MEDIUM / LOW]`

---

## 2. Asset Specifications

### Asset Type
- `[Cryptocurrency / Fiat / Securities / Other]`

### Asset Details
- **Asset Name:** `[e.g., Bitcoin, USD, Stock]`
- **Quantity:** `[Amount]`
- **Unit Value:** `[Price per unit]`
- **Total Value:** `[Quantity × Unit Value]`
- **Currency:** `[USD / EUR / BTC / Other]`

### Source Account
- **Account Type:** `[Personal / Business / Investment]`
- **Account Identifier:** `[Account #/Wallet Address - Anonymized]`
- **Current Balance:** `[Current amount in account]`

---

## 3. Approval Criteria

### Request Validation
- [ ] **Amount Verification** - Requested amount available in source?
- [ ] **Legal Compliance** - No regulatory restrictions?
- [ ] **Tax Obligations** - Tax implications reviewed?
- [ ] **Authorization** - Requester has authority to request?
- [ ] **Documentation** - All required docs attached?

### Approval Chain
1. **Level 1 (Department Head):**
   - Name: `[Name]`
   - Signature: `[Digital Signature]`
   - Date: `[Date]`
   - Status: `[APPROVED / REJECTED]`

2. **Level 2 (Finance Officer):**
   - Name: `[Name]`
   - Signature: `[Digital Signature]`
   - Date: `[Date]`
   - Status: `[APPROVED / REJECTED]`

3. **Level 3 (Legal/Compliance):**
   - Name: `[Name]`
   - Signature: `[Digital Signature]`
   - Date: `[Date]`
   - Status: `[APPROVED / REJECTED]`

---

## 4. Required Format

### Document Format Standards
```
Format Type: Markdown (.md)
Encoding: UTF-8
Line Endings: LF
Max File Size: 10MB
Required Sections: All 4 above
Metadata: Request ID, dates, signatures
```

### Submission Requirements
- **File Naming:** `request_[REQUEST-ID]_[DATE].md`
- **Location:** `/assets/requests/`
- **Backup:** Must be committed to GitHub with signature
- **Retention:** Keep for 7 years minimum
- **Confidentiality:** Mark as `[CONFIDENTIAL]` if needed

### Approval Documentation
- **Digital Signatures:** Required for all 3 levels
- **Timestamp:** Auto-generated on file creation
- **Audit Trail:** All changes tracked via Git history
- **Legal Binding:** All signatures legally binding

---

## Status Tracking

| Status | Meaning | Action |
|--------|---------|--------|
| `DRAFT` | In preparation | Complete sections 1-3 |
| `SUBMITTED` | Awaiting approval | Wait for Level 1 review |
| `LEVEL-1-APPROVED` | Department approved | Escalate to Level 2 |
| `LEVEL-2-APPROVED` | Finance approved | Escalate to Level 3 |
| `LEVEL-3-APPROVED` | Legal approved | Ready for execution |
| `REJECTED` | Not approved | Resubmit with revisions |
| `EXECUTED` | Transfer complete | Close request |
| `CANCELLED` | Request cancelled | Archive |

---

## Notes & Comments
```
[Add any additional notes, special conditions, or comments here]
```

---

**Template Version:** 1.0  
**Last Updated:** 2026-05-23  
**Owner:** HBReality  
**Repository:** contracts