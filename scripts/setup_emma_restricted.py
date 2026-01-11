#!/usr/bin/env python3
"""
Setup emma_restricted user with data-level filtering restrictions.
Denies access to France geography and Cotton commodity.
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from falkordb import FalkorDB
from src.security.auth import hash_password
import yaml

# Load config
with open('config/config.yaml', 'r') as f:
    config = yaml.safe_load(f)

# Connect to RBAC graph
db = FalkorDB(
    host=config['rbac'].get('host', 'localhost'),
    port=config['rbac'].get('port', 6379)
)
graph = db.select_graph(config['rbac']['graph_name'])

print("=" * 70)
print("Setting up emma_restricted user with data filtering")
print("=" * 70)

# 1. Create restricted_analyst role if it doesn't exist
print("\n1. Creating restricted_analyst role...")
query = """
MERGE (r:Role {name: 'restricted_analyst'})
ON CREATE SET 
    r.description = 'Analyst with data restrictions (no France, no Cotton)',
    r.is_system = false
RETURN r.name
"""
result = graph.query(query)
print(f"   ✓ Role: restricted_analyst")

# 2. Create node:deny:france permission
print("\n2. Creating node:deny:france permission...")
query = """
MERGE (p:Permission {name: 'node:deny:france'})
ON CREATE SET
    p.resource = 'node',
    p.action = 'read',
    p.description = 'Deny access to France geography nodes',
    p.grant_type = 'DENY',
    p.node_label = 'Geography',
    p.property_filter = '{"name": "France"}'
RETURN p.name
"""
result = graph.query(query)
print(f"   ✓ Permission: node:deny:france")

# 3. Link permission to role
query = """
MATCH (r:Role {name: 'restricted_analyst'})
MATCH (p:Permission {name: 'node:deny:france'})
MERGE (r)-[:HAS_PERMISSION]->(p)
RETURN r.name, p.name
"""
result = graph.query(query)
print(f"   ✓ Linked to restricted_analyst role")

# 4. Create node:deny:cotton permission
print("\n3. Creating node:deny:cotton permission...")
query = """
MERGE (p:Permission {name: 'node:deny:cotton'})
ON CREATE SET
    p.resource = 'node',
    p.action = 'read',
    p.description = 'Deny access to Cotton commodity nodes',
    p.grant_type = 'DENY',
    p.node_label = 'Commodity',
    p.property_filter = '{"name": "Cotton"}'
RETURN p.name
"""
result = graph.query(query)
print(f"   ✓ Permission: node:deny:cotton")

# 5. Link permission to role
query = """
MATCH (r:Role {name: 'restricted_analyst'})
MATCH (p:Permission {name: 'node:deny:cotton'})
MERGE (r)-[:HAS_PERMISSION]->(p)
RETURN r.name, p.name
"""
result = graph.query(query)
print(f"   ✓ Linked to restricted_analyst role")

# 6. Create property:deny:price permission
print("\n4. Creating property:deny:price permission...")
query = """
MERGE (p:Permission {name: 'property:deny:price'})
ON CREATE SET
    p.resource = 'property',
    p.action = 'read',
    p.description = 'Deny access to price property on BalanceSheet',
    p.grant_type = 'DENY',
    p.property_name = 'price'
RETURN p.name
"""
result = graph.query(query)
print(f"   ✓ Permission: property:deny:price")

# 7. Link permission to role
query = """
MATCH (r:Role {name: 'restricted_analyst'})
MATCH (p:Permission {name: 'property:deny:price'})
MERGE (r)-[:HAS_PERMISSION]->(p)
RETURN r.name, p.name
"""
result = graph.query(query)
print(f"   ✓ Linked to restricted_analyst role")

# 8. Create property:deny:confidential permission
print("\n5. Creating property:deny:confidential permission...")
query = """
MERGE (p:Permission {name: 'property:deny:confidential'})
ON CREATE SET
    p.resource = 'property',
    p.action = 'read',
    p.description = 'Deny access to confidential property',
    p.grant_type = 'DENY',
    p.property_name = 'confidential'
RETURN p.name
"""
result = graph.query(query)
print(f"   ✓ Permission: property:deny:confidential")

# 9. Link permission to role
query = """
MATCH (r:Role {name: 'restricted_analyst'})
MATCH (p:Permission {name: 'property:deny:confidential'})
MERGE (r)-[:HAS_PERMISSION]->(p)
RETURN r.name, p.name
"""
result = graph.query(query)
print(f"   ✓ Linked to restricted_analyst role")

# 10. Create or update emma_restricted user
print("\n6. Creating emma_restricted user...")
password_hash = hash_password("emma123")
query = """
MERGE (u:User {username: 'emma_restricted'})
ON CREATE SET
    u.password_hash = $password_hash,
    u.email = 'emma@example.com',
    u.full_name = 'Emma Restricted',
    u.is_active = true,
    u.is_superuser = false
ON MATCH SET
    u.password_hash = $password_hash,
    u.is_active = true
RETURN u.username
"""
result = graph.query(query, {'password_hash': password_hash})
print(f"   ✓ User: emma_restricted")

# 11. Assign role to user
query = """
MATCH (u:User {username: 'emma_restricted'})
MATCH (r:Role {name: 'restricted_analyst'})
MERGE (u)-[:HAS_ROLE]->(r)
RETURN u.username, r.name
"""
result = graph.query(query)
print(f"   ✓ Assigned role: restricted_analyst")

# 12. Verify setup
print("\n7. Verifying setup...")
query = """
MATCH (u:User {username: 'emma_restricted'})-[:HAS_ROLE]->(r:Role)-[:HAS_PERMISSION]->(p:Permission)
RETURN p.name, p.grant_type, p.node_label, p.property_filter, p.property_name
ORDER BY p.name
"""
result = graph.query(query)
print(f"   ✓ Emma's permissions:")
for row in result.result_set:
    perm_name = row[0]
    grant_type = row[1]
    node_label = row[2] if len(row) > 2 else None
    prop_filter = row[3] if len(row) > 3 else None
    prop_name = row[4] if len(row) > 4 else None
    
    print(f"      - {perm_name} ({grant_type})")
    if node_label:
        print(f"        Label: {node_label}, Filter: {prop_filter}")
    if prop_name:
        print(f"        Property: {prop_name}")

print("\n" + "=" * 70)
print("✅ Setup complete!")
print("=" * 70)
print("\nUser Credentials:")
print("  Username: emma_restricted")
print("  Password: emma123")
print("\nRestrictions:")
print("  ❌ Cannot see France (Geography nodes)")
print("  ❌ Cannot see Cotton (Commodity nodes)")
print("  ❌ Cannot see 'price' property")
print("  ❌ Cannot see 'confidential' property")
print("\nTest with:")
print("  python3 scripts/test_emma_filtering.sh")
print("=" * 70)
