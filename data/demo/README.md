# Demo Dataset

This directory contains sample demonstration data for testing and showcasing the Tijara Knowledge Graph system without using the full LDC production dataset.

## Overview

The demo dataset provides synthetic commodity trading data covering multiple countries, regions, and commodities. It's designed to:

- **Test system functionality** without requiring production LDC data
- **Demonstrate capabilities** to stakeholders and new users
- **Develop and debug** new features safely
- **Train users** on system operations

### Data Coverage

- **Geographic Scope**: Global (USA, Germany, France, Brazil, Morocco, China, India)
- **Commodities**: Corn, Wheat, Soybeans, Rice, Cotton, Coffee
- **Data Types**: Production, Exports, Demand, Yield, Price
- **Temporal Scope**: Monthly data for 2023

## Directory Structure

```
data/demo/
├── README.md                # This file
├── input/                   # Sample CSV files (optional)
│   └── sample_data.csv      # Example CSV format
└── docs/                    # Demo documentation
    └── sample_queries.md    # Example queries for demo data
```

## Dataset Characteristics

### Sample Data Structure

The demo dataset is programmatically generated and includes:

1. **Corn Production & Trade**
   - USA (Iowa): Production data
   - Germany (Bavaria): Production data
   - USA: Export data
   - Germany: Demand data

2. **Wheat Production & Yield**
   - France (Picardie): Production and yield data
   - Morocco: Production and yield data

3. **Soybeans Trade**
   - Brazil (Mato Grosso): Production and export data

4. **Rice, Cotton, Sugar, Coffee**
   - Multiple countries with diverse metrics

### Data Format

Demo data is ingested via the API `/ingest` endpoint in JSON format:

```json
{
  "data": [
    {"value": 384900, "year": 2023, "month": 1},
    {"value": 391200, "year": 2023, "month": 2},
    {"value": 398500, "year": 2023, "month": 3}
  ],
  "metadata": {
    "region": "Iowa",
    "country": "USA",
    "type": "Production",
    "commodity": "Corn",
    "unit": "thousand_metric_tons",
    "source": "USDA"
  }
}
```

## Loading Demo Data

### Prerequisites

- Python 3.11+
- API server running on `localhost:8000`
- FalkorDB running on `localhost:6379`

### Method 1: Using the Loading Script

Run the demo data loader:

```bash
# Start the API server first
python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8000

# In another terminal, load demo data
python3 scripts/demo/load_demo_data.py
```

**Expected Output:**
```
Loading sample data to Tijara Knowledge Graph...
✓ Loaded: Corn Production - Iowa, USA
✓ Loaded: Corn Production - Bavaria, Germany
✓ Loaded: Corn Exports - USA
✓ Loaded: Corn Demand - Germany
✓ Loaded: Wheat Production - Picardie, France
✓ Loaded: Wheat Production - Morocco
✓ Loaded: Wheat Yield - Picardie, France
✓ Loaded: Wheat Yield - Morocco
✓ Loaded: Soybeans Production - Mato Grosso, Brazil
✓ Loaded: Soybeans Exports - Brazil
...
✓ All sample data loaded successfully!
```

### Method 2: Using the Web UI

1. Open the web interface: `http://localhost:8000`
2. Navigate to the **Data Ingestion** tab
3. Use the **Sample Datasets** dropdown
4. Select "Commodity Production Data" or other samples
5. Click **Ingest Data**

### Method 3: Using the API Directly

```bash
curl -X POST http://localhost:8000/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "data": [
      {"value": 384900, "year": 2023, "month": 1},
      {"value": 391200, "year": 2023, "month": 2}
    ],
    "metadata": {
      "region": "Iowa",
      "country": "USA",
      "type": "Production",
      "commodity": "Corn",
      "unit": "thousand_metric_tons",
      "source": "Demo"
    }
  }'
```

## Demo vs. LDC Dataset

| Feature | Demo Dataset | LDC Dataset |
|---------|-------------|-------------|
| **Purpose** | Testing, demonstration, training | Production analysis |
| **Data Source** | Synthetic/sample | Official LDC CSV files |
| **Geographic Scope** | Global (7+ countries) | France-USA bilateral |
| **Data Volume** | Small (~100s of nodes) | Large (3,444 nodes) |
| **Structure** | Flexible JSON via API | Structured CSV with schema |
| **Loading Method** | API POST requests | Python scripts |
| **Graph Name** | `tijara_graph` (default) | `ldc_graph` |
| **Updates** | Easy to modify | Controlled, versioned |
| **Use Cases** | Development, demos, testing | Production queries, analysis |

## Sample Queries for Demo Data

After loading demo data, try these queries:

### Query 1: View All Commodities

```cypher
MATCH (c:Commodity)
RETURN c.name, c.type
ORDER BY c.name
LIMIT 20
```

### Query 2: Production by Country

```cypher
MATCH (c:Country)<-[:LOCATED_IN]-(r:Region)<-[:HAS_DATA]-(d:DataPoint)
WHERE d.type = 'Production'
RETURN c.name as country, sum(d.value) as total_production
ORDER BY total_production DESC
```

### Query 3: Commodities by Region

```cypher
MATCH (r:Region)-[:PRODUCES]->(c:Commodity)
RETURN r.name as region, collect(c.name) as commodities
ORDER BY r.name
```

### Query 4: Find Production Areas

```cypher
MATCH (r:Region)-[:PRODUCES]->(c:Commodity)
WHERE c.name = 'Corn'
RETURN r.name as region, r.country as country
```

## Creating Custom Demo Data

To add your own demo data:

### Option 1: Modify the Loading Script

Edit `scripts/demo/load_demo_data.py`:

```python
SAMPLE_DATA = [
    {
        "data": [
            {"value": 12000, "year": 2023, "month": 1},
            {"value": 12500, "year": 2023, "month": 2},
        ],
        "metadata": {
            "region": "Your Region",
            "country": "Your Country",
            "type": "Production",
            "commodity": "Your Commodity",
            "unit": "metric_tons",
            "source": "Custom"
        }
    }
]
```

### Option 2: Create CSV Files

Create a CSV file in `data/demo/input/`:

**sample_production.csv:**
```csv
country,region,commodity,year,month,value,unit
USA,Iowa,Corn,2023,1,384900,thousand_metric_tons
USA,Iowa,Corn,2023,2,391200,thousand_metric_tons
France,Picardie,Wheat,2023,1,36500,thousand_metric_tons
```

Then ingest via the web UI's CSV upload feature.

## Data Reset

To clear demo data and start fresh:

```bash
# Clear the default graph
python3 -c "
from falkordb import FalkorDB
db = FalkorDB(host='localhost', port=6379)
graph = db.select_graph('tijara_graph')
graph.query('MATCH (n) DETACH DELETE n')
print('Demo data cleared')
"
```

Or use the graph switch utility:

```bash
python3 switch_graph.py --clear tijara_graph
```

## Use Cases

### 1. Development & Testing

Load demo data for feature development without impacting production:

```bash
# Use demo graph for development
python3 scripts/demo/load_demo_data.py

# Test new features
python3 test_new_feature.py --graph tijara_graph
```

### 2. Training & Onboarding

Use demo data to train new team members:

1. Load demo data
2. Walk through web UI features
3. Practice writing Cypher queries
4. Test GraphRAG questions
5. Experiment with analytics

### 3. Stakeholder Demonstrations

Showcase capabilities without exposing sensitive LDC data:

- Natural language queries on sample trade flows
- Graph visualizations of production networks
- Impact analysis scenarios
- Analytics on synthetic data

### 4. Integration Testing

Test external integrations with predictable demo data:

```python
# Test API integration
response = requests.post('http://localhost:8000/ingest', json=demo_data)
assert response.status_code == 200

# Verify data was ingested
result = requests.get('http://localhost:8000/query', 
                     json={"query": "demo production data"})
assert len(result.json()['results']) > 0
```

## Demo Data Limitations

- **Not real data**: Values are synthetic and don't represent actual commodities
- **Simplified structure**: Fewer relationships and hierarchy levels than LDC data
- **No time series IDs**: Time series references are not linked to actual data sources
- **Limited history**: Only a few months of data, not multi-year
- **Inconsistent geography**: Geographic entities may not follow GID standards

## Switching Between Datasets

To switch between demo and LDC datasets:

```bash
# Use demo data (default)
export GRAPH_NAME=tijara_graph
python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8000

# Use LDC data
export GRAPH_NAME=ldc_graph
python3 -m uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Or use the graph switch utility:

```bash
python3 switch_graph.py --graph ldc_graph
```

## Support

For questions about the demo dataset:
- Review sample queries in `docs/sample_queries.md`
- Check the main README.md for general system documentation
- Experiment freely—demo data is designed to be modified!

## Tips for Demo Data

1. **Keep it simple**: Focus on clear, understandable examples
2. **Use realistic values**: Even synthetic data should be plausible
3. **Document your additions**: Add comments if you create custom demo data
4. **Clean up regularly**: Reset demo data between presentations
5. **Don't mix with production**: Keep demo and LDC graphs separate

## Version History

- **v1.0** (November 2024): Initial demo dataset
  - Global commodity coverage
  - Multiple data types (production, exports, yield)
  - API-based ingestion
