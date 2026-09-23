select ad_name
from bi.dbt_production_models.fct_facebook_granular_data
order by day desc
limit 1000;


-- Language_
-- ProductType_
-- ProductCategory_
-- Format_
-- LaunchDate_
-- ConceptName_
-- Hook_
-- Style_
-- Motivator_
-- Barriers_
-- Source_
-- CreatorName_
-- CreatorDemo_
-- VoiceoverAccent_
-- Persona_
-- Occasion_
-- Version_
-- Offer_
-- LandingPage_
-- WaveNumber_
-- VariantDescription_
-- SpecificConcept_
-- Relationship


-- EN_
-- WITW_
-- Kids_
-- LongVid_
-- 281025_
-- BedtimeUnboxing_
-- LightUp_
-- UGC_
-- _
-- _
-- Catalyst_
-- Danielle_
-- F30-40_
-- US-EN_
-- Music_
-- _
-- New_
-- _
-- ProductPage


select *
from bi.mark_dev.fct_facebook_granular_data
where ad_specific_concept != ''
limit 1000;

select *
from bi.mark_dev.fct_facebook_granular_data
where ad_relationship != ''
limit 1000;