# Asset Approval System - Complete Guide

## Overview
Automated GitHub-based asset approval workflow with three stages: Submit → Approve → Execute

---

## How It Works

### Stage 1: SUBMIT
- Create asset request file in `assets/` directory
- Use provided template
- Submit as Pull Request

### Stage 2: APPROVE
- Reviewer examines request
- Clicks "Approve" on PR
- Workflow validates automatically

### Stage 3: EXECUTE
- GitHub Actions executes automatically
- Asset allocated per request
- Decision logged with timestamp

---

## Quick Start

### 1. Create Asset Request
```bash
# Create file: assets/request_YYYYMMDD_001.md
# Fill with your asset details
```

### 2. Submit PR
- Commit your file
- Create Pull Request
- Add description

### 3. Request Approval
- Tag reviewers
- Wait for approval
- Workflow executes automatically

### 4. View Results
- Check Actions tab
- See execution logs
- Asset allocated & confirmed

---

## File Structure
```
contracts/
├── .github/
│   └── workflows/
│       └── asset-approval.yml      ← Workflow engine
├── assets/
│   ├── request_template.md         ← Use this template
│   └── request_*.md                ← Your submissions
└── ASSET_APPROVAL_GUIDE.md         ← This file
```

---

## Request Template

```markdown
# Asset Allocation Request

**Request ID:** [YYYYMMDD-001]
**Submitted by:** [Your Name]
**Date:** [Date]

## Asset Details
- Type: [Crypto/NFT/Token/Other]
- Amount: [Quantity]
- Destination: [Address/Account]

## Approval Status
- [ ] Pending Review
- [ ] Approved
- [ ] Executed

## Notes
[Additional details]
```

---

## Workflow Status

- **Validation:** Automatic on PR submission
- **Approval:** Manual review required
- **Execution:** Automatic on approval
- **Logging:** Automatic timestamp & confirmation

---

## Support
- Check Actions tab for logs
- Review workflow runs for status
- Contact maintainers for issues

**System is LIVE and READY.**
