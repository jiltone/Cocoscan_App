"""Static disease metadata used to enrich /api/classify responses and to
back the Treatment Plan / AI Treatment Assistant screens (report Table 3.2)."""

DISEASE_INFO = {
    "Bud_Root_Dropping": {
        "causal_agent": "Bud Root Dropping",
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "Remove dropped/rotting buds", "urgency": "Immediate",
             "description": "Clear fallen buds and roots from the base of the tree to stop the spread of secondary infection."},
            {"step": 2, "title": "Apply systemic fungicide", "urgency": "Within 48 hrs",
             "description": "Drench the crown with a systemic fungicide such as Hexaconazole as per label dosage."},
            {"step": 3, "title": "Improve drainage", "urgency": "This week",
             "description": "Waterlogging around the base is a common trigger — improve soil drainage around affected trees."},
        ],
    },
    "Bud_Rot": {
        "causal_agent": "Phytophthora palmivora",
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "Remove rotting bud tissue", "urgency": "Immediate",
             "description": "Cut away and destroy all visibly rotten spear leaf and bud tissue."},
            {"step": 2, "title": "Apply Bordeaux mixture", "urgency": "Within 48 hrs",
             "description": "Apply 1% Bordeaux mixture to the crown region to arrest fungal spread."},
            {"step": 3, "title": "Follow-up inspection", "urgency": "2 weeks",
             "description": "Re-inspect the crown; severely affected palms with a collapsed spear may need to be removed."},
        ],
    },
    "Gray_Leaf_Spot": {
        "causal_agent": "Pestalotiopsis palmarum",
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "Remove heavily spotted leaves", "urgency": "Within 24 hrs",
             "description": "Prune and destroy the most heavily infected leaflets to reduce spore load."},
            {"step": 2, "title": "Apply copper fungicide", "urgency": "Within 48 hrs",
             "description": "Spray copper oxychloride (3g/litre) focusing on leaf undersides."},
            {"step": 3, "title": "Improve air circulation", "urgency": "This week",
             "description": "Thin nearby vegetation — high humidity favours this fungus."},
        ],
    },
    "Healthy_Leaves": {
        "causal_agent": None,
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "No treatment required", "urgency": "N/A",
             "description": "This tree shows no visible signs of disease. Continue routine monitoring."},
        ],
    },
    "Leaf_Rot": {
        "causal_agent": "Colletotrichum gloeosporioides",
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "Remove infected leaflets", "urgency": "Within 24 hrs",
             "description": "Cut and destroy rotting leaf tissue before spores mature."},
            {"step": 2, "title": "Apply Mancozeb", "urgency": "Within 48 hrs",
             "description": "Spray Mancozeb 75% WP (2.5g/litre) as an alternative to copper-based fungicide."},
            {"step": 3, "title": "Follow-up inspection", "urgency": "2 weeks",
             "description": "Re-scan the tree; escalate to an agricultural officer if the rot continues to spread."},
        ],
    },
    "Leaf_Yellowing": {
        "causal_agent": "Nutrient deficiency / Weligama Coconut Leaf Wilt (WCLWD)",
        "curable": False,
        "warning": "Leaf Yellowing may indicate WCLWD phytoplasma, which is incurable. "
                   "If suspected, remove the infected tree immediately and contact your agricultural officer.",
        "treatment_steps": [
            {"step": 1, "title": "Conduct Soil & Leaf Nutrient Test", "urgency": "Immediate",
             "description": "Yellowing can be caused by potassium, magnesium, or boron deficiency. "
                             "Collect soil and leaf samples and send to your nearest agricultural lab before applying any treatment."},
            {"step": 2, "title": "Apply Deficient Nutrients", "urgency": "After lab results",
             "description": "Based on test results, apply the deficient element: potassium sulphate (500 g/tree), "
                             "magnesium sulphate (Epsom salt, 200 g/tree), or borax (30 g/tree). "
                             "Do not apply all at once without lab guidance."},
            {"step": 3, "title": "Check for WCLWD Phytoplasma", "urgency": "Within 48 hrs",
             "description": "If yellowing progresses from lower to upper fronds, nuts fall prematurely, or the spear leaf wilts "
                             "— suspect Weligama Coconut Leaf Wilt Disease. There is NO chemical cure."},
        ],
    },
    "Stem_Bleeding": {
        "causal_agent": "Thielaviopsis paradoxa",
        "curable": True,
        "warning": None,
        "treatment_steps": [
            {"step": 1, "title": "Scrape the bleeding patch", "urgency": "Immediate",
             "description": "Remove the affected bark and scrape away discoloured tissue until healthy wood is exposed."},
            {"step": 2, "title": "Apply fungicidal paste", "urgency": "Within 48 hrs",
             "description": "Apply Bordeaux paste or Tridemorph paste over the scraped wound."},
            {"step": 3, "title": "Re-inspect the trunk", "urgency": "2 weeks",
             "description": "Check that the bleeding has stopped and the wound is drying out cleanly."},
        ],
    },
}
