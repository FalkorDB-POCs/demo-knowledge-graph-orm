# LDC Dataset

This directory contains the official LDC (Louis Dreyfus Company) commodity trading dataset for France-USA trade analysis.

## Overview

The LDC dataset provides comprehensive commodity trade and production data for bilateral trade between France and the United States. This structured data forms the foundation of the Tijara Knowledge Graph system.

### Data Coverage

- **Geographic Scope**: France (FRA) and United States (USA)
- **Temporal Scope**: Current production and trade flows
- **Commodities**: 37 commodities across 8 major categories
- **Data Points**: 3,444 nodes, 14,714 relationships

## Directory Structure

```
data/ldc/
├── README.md                          # This file
├── input/                             # CSV data files (place your CSV files here)
│   ├── commodity_hierarchy.csv        # Commodity taxonomy (4 levels)
│   ├── flows.csv                      # Bilateral trade flows
│   ├── geometries.csv                 # Geographic hierarchy
│   ├── production_areas.csv           # Production zones by commodity
│   ├── balance_sheet.csv              # Supply/demand summaries
│   ├── balance_sheet_component.csv    # Balance sheet components
│   └── indicator_definition.csv       # Weather indicators
└── docs/                              # Additional documentation
    └── data_dictionary.md             # Field definitions and examples
```

## CSV File Formats

### 1. commodity_hierarchy.csv

4-level commodity taxonomy from broad categories to specific types.

**Format:**
```csv
Level0,Level1,Level2,Level3
Grains,Wheat,Common Wheat,Hard Red Wheat
Grains,Wheat,Durum Wheat,
Grains,Corn,Yellow Corn,
Oilseeds,Soybeans,Soybeans,
Cotton,Cotton,Upland Cotton,
```

**Fields:**
- `Level0`: Major category (e.g., Grains, Oilseeds, Cotton)
- `Level1`: Commodity type (e.g., Wheat, Corn, Soybeans)
- `Level2`: Variety (e.g., Common Wheat, Yellow Corn)
- `Level3`: Specific type (optional, e.g., Hard Red Wheat)

**Graph Representation:**
- Creates `Commodity` nodes with `SUBCLASS_OF` relationships forming hierarchy
- Properties: `name`, `level`, `category`, `parent_commodity`

---

### 2. flows.csv

Bilateral trade flows between France and USA for specific commodities.

**Format:**
```csv
source_country,destination_country,commodity,commodity_season,source_country_ts_id,destination_country_ts_id
FRA,USA,Common Wheat,,ts_fra_wheat_export,ts_usa_wheat_import
USA,FRA,Yellow Corn,,ts_usa_corn_export,ts_fra_corn_import
FRA,USA,Barley,,ts_fra_barley_export,ts_usa_barley_import
```

**Fields:**
- `source_country`: Exporting country GID code (FRA or USA)
- `destination_country`: Importing country GID code
- `commodity`: Commodity name (must match commodity_hierarchy.csv)
- `commodity_season`: Optional season identifier
- `source_country_ts_id`: Time series ID for export data
- `destination_country_ts_id`: Time series ID for import data

**Graph Representation:**
- Creates `TRADES_WITH` relationships between Geography nodes
- Properties: `commodity`, `season`, `source_ts_id`, `destination_ts_id`, `flow_type`

---

### 3. geometries.csv

Hierarchical geographic data (countries, regions/states, sub-regions).

**Format:**
```csv
gid_code,name,level,parent_gid_code
FRA,France,0,
USA,United States,0,
FRA.1,Île-de-France,1,FRA
FRA.2,Hauts-de-France,1,FRA
USA.IA,Iowa,1,USA
USA.IL,Illinois,1,USA
```

**Fields:**
- `gid_code`: Unique geographic identifier (GID standard)
- `name`: Human-readable location name
- `level`: Hierarchy level (0=country, 1=region/state, 2=sub-region)
- `parent_gid_code`: Parent geography GID (empty for countries)

**Graph Representation:**
- Creates `Geography` nodes with labels: `Country` (level 0), `Region` (level 1), `SubRegion` (level 2)
- `LOCATED_IN` relationships link children to parents
- Properties: `gid_code`, `name`, `level`

---

### 4. production_areas.csv

Geographic zones where specific commodities are produced.

**Format:**
```csv
production_area_id,crop_mask_id,gid_code,commodity_name,season
pa_fra_wheat_01,cm_wheat_winter,FRA.1,Common Wheat,winter
pa_fra_wheat_02,cm_wheat_winter,FRA.2,Common Wheat,winter
pa_usa_corn_01,cm_corn,USA.IA,Yellow Corn,
pa_usa_corn_02,cm_corn,USA.IL,Yellow Corn,
```

**Fields:**
- `production_area_id`: Unique production area identifier
- `crop_mask_id`: Crop mask/satellite imagery identifier
- `gid_code`: Geographic location (references geometries.csv)
- `commodity_name`: Commodity produced (references commodity_hierarchy.csv)
- `season`: Growing season (optional)

**Graph Representation:**
- Creates `ProductionArea` nodes
- `PRODUCES` relationship to Commodity
- `LOCATED_IN` relationship to Geography
- Properties: `production_area_id`, `crop_mask_id`, `commodity`, `season`

---

### 5. balance_sheet.csv

Supply and demand balance sheets for commodities by country.

**Format:**
```csv
id,gid,product_name,product_season
bs_usa_corn_001,USA,Yellow Corn,
bs_fra_wheat_001,FRA,Common Wheat,winter
bs_fra_wheat_002,FRA,Durum Wheat,
bs_usa_soybeans_001,USA,Soybeans,
```

**Fields:**
- `id`: Unique balance sheet identifier
- `gid`: Country GID code (FRA or USA)
- `product_name`: Commodity name (references commodity_hierarchy.csv)
- `product_season`: Optional season identifier

**Graph Representation:**
- Creates `BalanceSheet` nodes
- `FOR_GEOGRAPHY` relationship to Country
- `FOR_COMMODITY` relationship to Commodity
- Properties: `balance_sheet_id`, `gid`, `product_name`, `season`

---

### 6. balance_sheet_component.csv

Components that make up balance sheets (yield, area, stocks, consumption).

**Format:**
```csv
balancesheet_id,component_id,component_type
bs_usa_corn_001,comp_yield,Yield
bs_usa_corn_001,comp_harvested_area,HarvestedArea
bs_usa_corn_001,comp_carry_in,CarryIn
bs_usa_corn_001,comp_carry_out,CarryOut
bs_usa_corn_001,comp_consumption,Consumption
```

**Fields:**
- `balancesheet_id`: References balance_sheet.csv `id`
- `component_id`: Unique component identifier
- `component_type`: Component type (Yield, HarvestedArea, CarryIn, CarryOut, Consumption, etc.)

**Graph Representation:**
- Creates `Component` nodes
- `HAS_COMPONENT` relationship from BalanceSheet to Component
- Properties: `component_id`, `component_type`

---

### 7. indicator_definition.csv

Weather and climate indicators used for production monitoring.

**Format:**
```csv
id,name,indicator,sourceName,forecastDays,forecastType,unit
ind_temp_001,Temperature 2m,temperature_2m,ECMWF IFS,10,ensemble,celsius
ind_precip_001,Total Precipitation,total_precipitation,NCEP GEFS,15,ensemble,mm
ind_soil_001,Soil Moisture,soil_moisture_0_10cm,ECMWF AIFS,7,deterministic,m3/m3
```

**Fields:**
- `id`: Unique indicator identifier
- `name`: Human-readable indicator name
- `indicator`: Technical indicator name
- `sourceName`: Data source (ECMWF IFS, NCEP GEFS, etc.)
- `forecastDays`: Forecast horizon in days
- `forecastType`: Forecast type (ensemble, deterministic)
- `unit`: Measurement unit

**Graph Representation:**
- Creates `Indicator` nodes with label `WeatherIndicator`
- Properties: `indicator_id`, `name`, `indicator_type`, `source_name`, `forecast_days`, `forecast_type`, `unit`

## Loading the Data

### Prerequisites

- Python 3.11+
- FalkorDB running on localhost:6379
- OpenAI API key (for Graphiti semantic search)
- Dependencies installed: `pip install -r requirements.txt`

### Step 1: Place CSV Files

Place all CSV files in the `data/ldc/input/` directory:

```bash
# Ensure all required CSV files are present
ls data/ldc/input/
# Should show:
# commodity_hierarchy.csv
# flows.csv
# geometries.csv
# production_areas.csv
# balance_sheet.csv
# balance_sheet_component.csv
# indicator_definition.csv
```

### Step 2: Configure System

Edit `config/config.yaml`:

```yaml
falkordb:
  host: localhost
  port: 6379
  graph_name: ldc_graph

openai:
  api_key: "your-openai-api-key"
```

### Step 3: Load to FalkorDB

Load structured data into the `ldc_graph` database:

```bash
python3 scripts/ldc/load_ldc_data.py
```

**Expected Output:**
```
🚀 LDC Data Loader
==============================================================
📦 Loading commodity hierarchy...
✓ Loaded 37 commodity nodes

🌍 Loading geographic hierarchy...
✓ Loaded 3,310 geography nodes

🌡️  Loading weather indicator definitions...
✓ Loaded 9 indicator definitions

🌾 Loading production areas...
✓ Loaded 16 unique production areas

📊 Loading balance sheets...
✓ Loaded 12 balance sheets

📈 Loading balance sheet components...
✓ Loaded 60 balance sheet components

🔄 Loading trade flows...
✓ Loaded 9 trade flows

📊 LDC Graph Statistics
==============================================================
Nodes:
  Geography: 3,310
  Commodity: 37
  Component: 60
  ProductionArea: 16
  BalanceSheet: 12
  Indicator: 9
  TOTAL: 3,444

Relationships:
  LOCATED_IN: 14,576
  HAS_COMPONENT: 60
  SUBCLASS_OF: 29
  PRODUCES: 16
  FOR_COMMODITY: 12
  FOR_GEOGRAPHY: 12
  TRADES_WITH: 9
  TOTAL: 14,714

✅ LDC data loading complete!
```

### Step 4: Load to Graphiti (Optional)

Load semantic embeddings for natural language queries:

```bash
python3 scripts/ldc/load_ldc_graphiti.py
```

This creates semantic episodes in the `graphiti` graph for GraphRAG queries.

## Data Validation

After loading, verify the data:

```bash
# Count nodes by type
python3 -c "
from falkordb import FalkorDB
db = FalkorDB(host='localhost', port=6379)
graph = db.select_graph('ldc_graph')
result = graph.query('MATCH (n) RETURN labels(n)[0] as type, count(n) as count ORDER BY count DESC')
for row in result.result_set:
    print(f'{row[0]}: {row[1]}')
"

# Check trade flows
python3 -c "
from falkordb import FalkorDB
db = FalkorDB(host='localhost', port=6379)
graph = db.select_graph('ldc_graph')
result = graph.query('MATCH (s:Country)-[t:TRADES_WITH]->(d:Country) RETURN s.name, d.name, t.commodity')
for row in result.result_set:
    print(f'{row[0]} → {row[1]}: {row[2]}')
"
```

## Data Updates

To update the dataset:

1. Place updated CSV files in `data/ldc/input/`
2. Re-run the loading script (it clears the graph first):
   ```bash
   python3 scripts/ldc/load_ldc_data.py
   ```
3. Optionally reload Graphiti:
   ```bash
   python3 scripts/ldc/load_ldc_graphiti.py
   ```

## Graph Schema

### Node Types

- **Geography** (Country, Region, SubRegion): Geographic entities
- **Commodity** (Category, Variety, Type): Commodity hierarchy
- **ProductionArea**: Geographic zones for commodity production
- **BalanceSheet**: Supply/demand summaries
- **Component**: Balance sheet components
- **Indicator** (WeatherIndicator): Climate/weather indicators

### Relationship Types

- **LOCATED_IN**: Geographic hierarchy (Geography → Geography, ProductionArea → Geography)
- **SUBCLASS_OF**: Commodity hierarchy (Commodity → Commodity)
- **PRODUCES**: Production relationship (ProductionArea → Commodity)
- **TRADES_WITH**: Trade flows (Geography → Geography)
- **FOR_GEOGRAPHY**: Balance sheet location (BalanceSheet → Geography)
- **FOR_COMMODITY**: Balance sheet commodity (BalanceSheet → Commodity)
- **HAS_COMPONENT**: Component relationship (BalanceSheet → Component)

## Key Statistics

- **Total Nodes**: 3,444
- **Total Relationships**: 14,714
- **Countries**: 2 (France, USA)
- **Commodities**: 37 across 8 categories
- **Trade Flows**: 9 bilateral flows
- **Production Areas**: 16 zones
- **Balance Sheets**: 12 summaries
- **Weather Indicators**: 9 variables

## Support

For questions about the LDC dataset:
- Check field definitions in `docs/data_dictionary.md`
- Review graph structure in main README.md
- Contact the LDC Data & Analytics team

## Version History

- **v1.0** (November 2024): Initial LDC production dataset
  - France-USA bilateral trade coverage
  - 37 commodities with full hierarchy
  - Geographic data for both countries
  - Production areas and balance sheets
