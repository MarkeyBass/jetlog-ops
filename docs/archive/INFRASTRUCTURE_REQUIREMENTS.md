> **HISTORICAL — frozen, kept for the record. Do not follow or edit it.** This is an early cloud plan (AWS + Supabase). Superseded by the decision to deploy on IsraJet's own on-prem machines — see [DECISIONS.md](../DECISIONS.md) and the runbook, [DEPLOY.md](../../../jetlog/docs/DEPLOY.md). Moved to `docs/archive/` on 2026-10-14; links inside may point at old paths.

# Infrastructure Requirements

## Production

- **Region:** AWS Israel (`il-central-1`).
- **Application servers:** 2 × `t4g.small` EC2 instances in separate availability zones.
- **Storage:** 20 GB gp3 EBS per instance.
- **Deployment:** Docker Compose; application containers must be stateless.
- **Traffic:** Internet-facing Application Load Balancer with HTTPS, ACM certificate, and health checks.
- **DNS:** Route 53.
- **Database:** Supabase Pro with Small compute, hosted in Frankfurt; PostgreSQL connection pooling and TLS required.
- **Backups:** Supabase daily backups with seven-day retention.
- **Access:** AWS Systems Manager instead of public SSH; EC2 inbound traffic restricted to the load balancer.
- **Monitoring:** CloudWatch logs, uptime alarms, CPU/memory/disk alerts, and an AWS billing alarm.

Estimated production cost: **about $100 / ₪305 per month before VAT**, with a recommended client budget of **₪400 per month including VAT and contingency**.

## Development

- 1 × `t4g.small` EC2 instance with 20 GB gp3 EBS.
- Application and PostgreSQL run locally with Docker Compose.
- No load balancer or separate paid database is required.
- Stop the instance outside working hours where practical.

Estimated development cost: **up to $20 / ₪71 per month including VAT**. Budget **₪100 per month**.

## Ownership

AWS, Supabase, DNS, backups, payment methods, and administrative accounts should be owned and paid directly by the client. Deployment, monitoring response, and ongoing maintenance are separate service costs.
