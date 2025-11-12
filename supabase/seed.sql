-- Seed Data for Greenline SaaS
-- Run this AFTER running schema.sql
-- This populates the global plant database (organization_id = NULL means available to all orgs)

-- ============================================
-- GLOBAL PLANT DATABASE
-- ============================================
-- These plants are available to all organizations

INSERT INTO plants (name, scientific_name, type, is_native, sun_requirement, water_requirement, mature_height, mature_width, growth_rate, hardiness_zone, description, care_notes, price, image_url) VALUES

-- TREES
('Red Maple', 'Acer rubrum', 'tree', true, 'full_sun', 'medium', '40-60 ft', '30-50 ft', 'fast', '3-9', 'Native deciduous tree with brilliant red fall color. Excellent shade tree for landscapes.', 'Tolerates wet soils. Prune in late fall to winter. Watch for verticillium wilt.', 125.00, NULL),

('River Birch', 'Betula nigra', 'tree', true, 'full_sun', 'high', '40-70 ft', '40-60 ft', 'fast', '4-9', 'Native tree with attractive peeling bark. Excellent for wet sites and stream banks.', 'Prefers moist soil. Resistant to bronze birch borer. Prune in late summer.', 150.00, NULL),

('Eastern Redbud', 'Cercis canadensis', 'tree', true, 'part_sun', 'medium', '20-30 ft', '25-35 ft', 'medium', '4-9', 'Native understory tree with stunning pink spring blooms before leaves emerge.', 'Tolerates shade and various soils. Plant in spring. Watch for canker diseases.', 85.00, NULL),

('American Holly', 'Ilex opaca', 'tree', true, 'part_sun', 'medium', '15-30 ft', '10-20 ft', 'slow', '5-9', 'Native evergreen with glossy leaves and red berries. Birds love the winter berries.', 'Plant male and female for berries. Prune in late winter. Prefers acidic soil.', 95.00, NULL),

('Crape Myrtle', 'Lagerstroemia indica', 'tree', false, 'full_sun', 'low', '15-25 ft', '6-15 ft', 'medium', '7-9', 'Popular ornamental with showy summer blooms in pink, red, white, or purple.', 'Prune in late winter. Resistant to powdery mildew. Drought tolerant once established.', 65.00, NULL),

('Willow Oak', 'Quercus phellos', 'tree', true, 'full_sun', 'medium', '40-75 ft', '25-50 ft', 'medium', '5-9', 'Native oak with willow-like leaves. Excellent large shade tree for spacious landscapes.', 'Tolerates wet soils. Relatively fast growing for an oak. Low maintenance.', 175.00, NULL),

-- SHRUBS
('Bottlebrush Buckeye', 'Aesculus parviflora', 'shrub', true, 'part_shade', 'medium', '8-12 ft', '8-15 ft', 'medium', '4-8', 'Native shrub with showy white flower spikes in summer. Great for woodland gardens.', 'Spreads by suckers. Tolerates shade and various soils. Low maintenance.', 45.00, NULL),

('Butterfly Bush', 'Buddleia davidii', 'shrub', false, 'full_sun', 'low', '4-8 ft', '4-6 ft', 'fast', '5-9', 'Fast-growing shrub with fragrant flowers that attract butterflies and hummingbirds.', 'Deadhead for continuous blooms. Cut back hard in late winter. Drought tolerant.', 35.00, NULL),

('Sweetshrub', 'Calycanthus floridus', 'shrub', true, 'part_shade', 'medium', '6-10 ft', '6-12 ft', 'medium', '4-9', 'Native shrub with fragrant burgundy flowers in spring. Aromatic foliage.', 'Tolerates shade and various soils. Prune after flowering. Relatively pest-free.', 38.00, NULL),

('Summersweet', 'Clethra alnifolia', 'shrub', true, 'part_sun', 'high', '3-8 ft', '4-6 ft', 'medium', '3-9', 'Native shrub with fragrant white flower spikes in mid-summer. Great for wet areas.', 'Prefers moist, acidic soil. Spreads slowly by suckers. Prune in early spring.', 32.00, NULL),

('Oakleaf Hydrangea', 'Hydrangea quercifolia', 'shrub', true, 'part_shade', 'medium', '4-6 ft', '4-6 ft', 'medium', '5-9', 'Native hydrangea with oak-shaped leaves and showy white flower clusters.', 'Blooms on old wood. Prune right after flowering. Tolerates drought once established.', 42.00, NULL),

('Inkberry Holly', 'Ilex glabra', 'shrub', true, 'part_sun', 'medium', '5-8 ft', '5-8 ft', 'slow', '5-9', 'Native evergreen holly with dark green foliage. Excellent hedge or foundation plant.', 'Prune in spring to maintain shape. Tolerates wet soils. Plant female for berries.', 38.00, NULL),

('Mountain Laurel', 'Kalmia latifolia', 'shrub', true, 'part_shade', 'medium', '7-15 ft', '7-15 ft', 'slow', '4-9', 'Native evergreen with spectacular spring blooms. State flower of Pennsylvania.', 'Requires acidic soil. Remove spent flowers. Mulch to keep roots cool.', 48.00, NULL),

('Wax Myrtle', 'Morella cerifera', 'shrub', true, 'full_sun', 'medium', '10-15 ft', '10-15 ft', 'fast', '7-11', 'Native evergreen shrub with aromatic foliage. Can be pruned as small tree.', 'Very adaptable. Tolerates salt and poor soil. Fast growing screen plant.', 36.00, NULL),

('Virginia Sweetspire', 'Itea virginica', 'shrub', true, 'part_sun', 'high', '3-6 ft', '3-6 ft', 'medium', '5-9', 'Native shrub with fragrant white flower spikes and brilliant red fall color.', 'Tolerates wet soils and shade. Spreads by suckers. Low maintenance.', 32.00, NULL),

-- PERENNIALS
('Swamp Milkweed', 'Asclepias incarnata', 'perennial', true, 'full_sun', 'high', '3-5 ft', '2-3 ft', 'fast', '3-9', 'Native perennial essential for monarch butterflies. Pink flower clusters in summer.', 'Host plant for monarch caterpillars. Prefers moist soil. Self-seeds readily.', 18.00, NULL),

('False Indigo', 'Baptisia australis', 'perennial', true, 'full_sun', 'low', '3-4 ft', '3-4 ft', 'slow', '3-9', 'Native perennial with blue-purple flower spikes and attractive seed pods.', 'Drought tolerant once established. Deep taproot - hard to transplant. Long-lived.', 22.00, NULL),

('Purple Coneflower', 'Echinacea purpurea', 'perennial', true, 'full_sun', 'low', '2-4 ft', '1-2 ft', 'medium', '3-8', 'Iconic native perennial with purple-pink daisy-like flowers. Attracts butterflies.', 'Deadhead for more blooms. Leave seedheads for birds in winter. Drought tolerant.', 16.00, NULL),

('Joe Pye Weed', 'Eutrochium purpureum', 'perennial', true, 'full_sun', 'high', '4-7 ft', '2-4 ft', 'fast', '4-9', 'Tall native perennial with mauve-pink flower clusters. Butterfly magnet.', 'Prefers moist soil. Can be cut back in spring for shorter plants. Self-seeds.', 20.00, NULL),

('Coral Bells', 'Heuchera spp.', 'perennial', false, 'part_shade', 'medium', '8-18 in', '12-18 in', 'medium', '4-9', 'Ornamental foliage plant in various colors. Delicate flower spikes in spring.', 'Mulch in winter. Divide every 3-4 years. Prefers well-drained soil.', 15.00, NULL),

('Black-eyed Susan', 'Rudbeckia hirta', 'perennial', true, 'full_sun', 'low', '1-3 ft', '12-18 in', 'fast', '3-9', 'Cheerful native perennial with golden-yellow flowers. Blooms all summer.', 'Very low maintenance. Drought tolerant. Self-seeds readily. Cut back in spring.', 14.00, NULL),

('Goldenrod', 'Solidago spp.', 'perennial', true, 'full_sun', 'low', '2-5 ft', '2-3 ft', 'fast', '3-9', 'Native perennial with bright yellow plumes in fall. Does not cause allergies!', 'Tolerates poor soil. Drought tolerant. Can be aggressive - choose cultivars.', 16.00, NULL),

-- GRASSES
('Little Bluestem', 'Schizachyrium scoparium', 'grass', true, 'full_sun', 'low', '2-4 ft', '1-2 ft', 'medium', '3-9', 'Native ornamental grass with blue-green foliage turning bronze-red in fall.', 'Very low maintenance. Drought tolerant. Cut back in late winter. Good for slopes.', 18.00, NULL),

('Switchgrass', 'Panicum virgatum', 'grass', true, 'full_sun', 'low', '3-6 ft', '2-3 ft', 'fast', '5-9', 'Native ornamental grass with airy seed heads. Many cultivars available.', 'Tolerates clay and wet soils. Drought tolerant once established. Cut back in spring.', 20.00, NULL),

('Muhly Grass', 'Muhlenbergia capillaris', 'grass', true, 'full_sun', 'low', '2-3 ft', '2-3 ft', 'medium', '6-9', 'Native grass with spectacular pink-purple plumes in fall. Showstopper!', 'Very drought tolerant. Prefers well-drained soil. Cut back in late winter.', 24.00, NULL),

-- GROUNDCOVERS
('Wild Ginger', 'Asarum canadense', 'groundcover', true, 'full_shade', 'medium', '4-6 in', '12-18 in', 'slow', '3-8', 'Native groundcover for deep shade with heart-shaped leaves.', 'Excellent for woodland gardens. Spreads slowly. Prefers rich, moist soil.', 12.00, NULL),

('Green and Gold', 'Chrysogonum virginianum', 'groundcover', true, 'part_shade', 'medium', '6-12 in', '12-18 in', 'medium', '5-9', 'Native groundcover with bright yellow flowers from spring through fall.', 'Tolerates shade and dry soil. Evergreen in mild climates. Low maintenance.', 13.00, NULL),

('Creeping Phlox', 'Phlox stolonifera', 'groundcover', true, 'part_shade', 'medium', '6-12 in', '12-24 in', 'medium', '3-8', 'Native groundcover with carpet of blue, pink, or white flowers in spring.', 'Excellent for slopes. Prefers well-drained soil. Shear after flowering.', 14.00, NULL),

('Partridgeberry', 'Mitchella repens', 'groundcover', true, 'part_shade', 'medium', '2-3 in', '12-24 in', 'slow', '3-9', 'Native evergreen groundcover with red berries in winter. Great under trees.', 'Prefers acidic soil. Slow growing but worth the wait. Very shade tolerant.', 11.00, NULL),

-- VINES
('Crossvine', 'Bignonia capreolata', 'vine', true, 'full_sun', 'medium', '30-50 ft', 'variable', 'fast', '6-9', 'Native evergreen vine with orange-red trumpet flowers in spring.', 'Fast growing. Needs strong support. Prune after flowering. Semi-evergreen.', 28.00, NULL),

('Coral Honeysuckle', 'Lonicera sempervirens', 'vine', true, 'full_sun', 'medium', '10-20 ft', 'variable', 'fast', '4-9', 'Native vine with tubular coral-red flowers. Hummingbird favorite!', 'Non-invasive unlike Japanese honeysuckle. Blooms spring through fall. Low maintenance.', 25.00, NULL);

-- ============================================
-- GLOBAL MATERIALS DATABASE
-- ============================================

INSERT INTO materials (name, type, unit, price_per_unit, supplier, notes) VALUES
('Premium Topsoil', 'soil', 'cubic_yard', 45.00, 'Local Supplier', 'High quality screened topsoil for planting beds'),
('Garden Soil Mix', 'soil', 'cubic_yard', 52.00, 'Local Supplier', 'Enriched with compost, ideal for vegetable gardens'),
('Hardwood Mulch', 'mulch', 'cubic_yard', 38.00, 'Local Supplier', 'Double-ground hardwood, natural brown color'),
('Pine Bark Mulch', 'mulch', 'cubic_yard', 42.00, 'Local Supplier', 'Long-lasting pine bark nuggets'),
('Cedar Mulch', 'mulch', 'cubic_yard', 55.00, 'Local Supplier', 'Natural insect repellent, aromatic'),
('Compost', 'compost', 'cubic_yard', 48.00, 'Local Supplier', 'Aged leaf compost, excellent soil amendment'),
('Mushroom Compost', 'compost', 'cubic_yard', 52.00, 'Local Supplier', 'Rich organic matter, slightly alkaline'),
('Pea Gravel', 'gravel', 'cubic_yard', 65.00, 'Local Supplier', '3/8" rounded gravel for paths and drainage'),
('#57 Stone', 'stone', 'cubic_yard', 58.00, 'Local Supplier', '3/4" crushed limestone for drainage'),
('River Rock', 'stone', 'cubic_yard', 85.00, 'Local Supplier', '2-4" decorative river stone');

-- ============================================
-- INDEXES AND FINAL SETUP
-- ============================================

-- Refresh statistics
ANALYZE plants;
ANALYZE materials;

-- Verify data
SELECT 
  type,
  COUNT(*) as count,
  COUNT(*) FILTER (WHERE is_native = true) as native_count
FROM plants
WHERE organization_id IS NULL
GROUP BY type
ORDER BY type;

COMMENT ON TABLE plants IS 'Global plant database now seeded with 32+ native and ornamental plants';
COMMENT ON TABLE materials IS 'Global materials database seeded with common landscaping materials';
