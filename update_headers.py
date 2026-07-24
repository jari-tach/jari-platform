import os

docs_dir = 'docs'
files = [f'0{i}_{name}.md' for i, name in [
    (1, 'BUSINESS_VISION'), (2, 'SYSTEM_ARCHITECTURE'), (3, 'ENTERPRISE_ARCHITECTURE'),
    (4, 'CLEAN_ARCHITECTURE'), (5, 'FOLDER_STRUCTURE'), (6, 'CODING_STANDARDS'),
    (7, 'NAMING_CONVENTION'), (8, 'UI_DESIGN_SYSTEM'), (9, 'DATABASE_ARCHITECTURE'),
    (10, 'PRODUCT_CATALOG_ARCHITECTURE'), (11, 'WHOLESALE_MARKET_ARCHITECTURE'),
    (12, 'DELIVERY_ENGINE'), (13, 'API_ARCHITECTURE'), (14, 'SECURITY_GUIDE'),
    (15, 'OFFLINE_GUIDE'), (16, 'LOGGING_GUIDE'), (17, 'ERROR_HANDLING'),
    (18, 'TESTING_GUIDE'), (19, 'DEPLOYMENT_GUIDE'), (20, 'DEVELOPMENT_ROADMAP'),
    (21, 'AI_ROADMAP'), (22, 'SAUDI_COMPLIANCE'), (23, 'CHANGELOG'), (24, 'INDEX'),
]]

old = '> **Author:** Senior Flutter Software Engineer  \n> **Related:'
new = '> **Author:** Senior Flutter Software Engineer  \n> **Review Date:** 2026-07-23  \n> **Next Review:** 2027-01-23  \n> **Related:'

for fname in files:
    fpath = os.path.join(docs_dir, fname)
    if not os.path.exists(fpath):
        print(f'SKIP (not found): {fname}')
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'Review Date' in content:
        print(f'SKIP (already has Review Date): {fname}')
        continue
    if old in content:
        content = content.replace(old, new, 1)
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'UPDATED: {fname}')
    else:
        print(f'PATTERN NOT FOUND: {fname}')

print('Done!')
