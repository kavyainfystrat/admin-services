-- ---------------------------------------------------------------------------------------------------------
-- Database Name: mosip_master
-- Release Version 	: 1.2.0
-- Purpose    		: Database Alter scripts for the release for Master DB.       
-- Create By   		: Ram Bhatt
-- Created Date		: March-2021
-- 
-- Modified Date        Modified By         Comments / Remarks
-- -----------------------------------------------------------------------------------------------------------
-- Apr-2021		Ram Bhatt  	   Removed bulk upload transaction size limit
-- Apr-2021		Ram Bhatt	   Lang_code nullable, removed from pk constraints and multiple FK constraint changes	
-- Apr-2021 		Ram Bhatt          Added new rows in template,template_type and module_detail csv
-- Apr-2021 		Ram Bhatt  	   Creation of master.permitted_local_config
-- May-2021		Ram Bhatt	   Changed Precision and size of version and identity_schema_version
-- Jul-2021		Ram Bhatt          Creation of blocklisted table
-- Aug-2021		Ram Bhatt	   Remove primary key constraint from blacklisted table
-- Aug-2021		Ram Bhatt	   Column size increased for template_typ_code and code column
-- ------------------------------------------------------------------------------------------------------------

\c mosip_master sysadmin
-----------------------------------------------------------------------------------------------------------------------

ALTER TABLE master.template_type ALTER COLUMN code TYPE character varying(64) ;
ALTER TABLE master.template ALTER COLUMN template_typ_code TYPE character varying(64) ;


DROP TABLE IF EXISTS master.template_migr_bkp;
SELECT * INTO master.template_migr_bkp FROM master.template;
-- cleanup to map only registration-client related templates with 10002 moduleId and 
-- other reg email and sms templates mapped to 10002 is remapped to pre-reg moduleId 10001 
-- This cleanup is performed to avoid un-related templates to get synced in reg-client.
UPDATE master.template set module_id='10001' where module_id='10002' and template_typ_code not like 'reg-%';
UPDATE master.template set module_id='10002' where template_typ_code like 'reg-ack%';
UPDATE master.template set module_id='10002' where template_typ_code like 'reg-preview%';
UPDATE master.template set module_id='10002' where template_typ_code like 'reg-dashboard%';
DROP TABLE IF EXISTS master.template_migr_bkp;

--------------------------------------------------------------------------------------------------------------------
ALTER TABLE master.blacklisted_words DROP CONSTRAINT IF EXISTS pk_blwrd_code CASCADE;
\ir ../ddl/master-blocklisted_words.sql
ALTER TABLE master.blocklisted_words DROP CONSTRAINT IF EXISTS pk_blwrd_code CASCADE;
ALTER TABLE master.blocklisted_words ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.blocklisted_words ADD CONSTRAINT pk_blwrd_code PRIMARY KEY (word);
INSERT into master.blocklisted_words (word,descr,lang_code,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) SELECT distinct word,descr,lang_code,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes FROM master.blacklisted_words;
DROP TABLE IF EXISTS master.blacklisted_words;

-------------------------------------------UI SPEC TABLE ----------------------------------------------

DROP TABLE IF EXISTS master.identity_schema_migr_bkp;
CREATE TABLE identity_schema_migr_bkp AS (SELECT * FROM master.identity_schema);

\ir ../ddl/master-ui_spec.sql
TRUNCATE TABLE master.ui_spec cascade;
INSERT into master.ui_spec (id,version,domain,title,description,type,json_spec,identity_schema_id,identity_schema_version,effective_from,status_code,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes) SELECT id,id_version,'registration-client', title,description,'schema',id_attr_json,id,id_version,effective_from,status_code,is_active,cr_by,cr_dtimes,upd_by,upd_dtimes,is_deleted,del_dtimes FROM master.identity_schema;

ALTER TABLE master.identity_schema DROP COLUMN id_attr_json;
DROP TABLE IF EXISTS master.identity_schema_migr_bkp;
--------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE master.bulkupload_transaction ALTER COLUMN upload_description TYPE character varying;

-----------------------------------------------ALTER FK constraints with lang code -----------------------------------------------------------

ALTER TABLE master.device_master DROP CONSTRAINT IF EXISTS fk_devicem_dspec CASCADE;
ALTER TABLE master.device_master ADD CONSTRAINT fk_devicem_dspec FOREIGN KEY (dspec_id)
REFERENCES master.device_spec (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.device_master DROP CONSTRAINT IF EXISTS fk_devicem_zone CASCADE;
ALTER TABLE master.device_master ADD CONSTRAINT fk_devicem_zone FOREIGN KEY (zone_code)
REFERENCES master.zone (code) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.device_master DROP CONSTRAINT IF EXISTS fk_devicem_center CASCADE;
ALTER TABLE master.device_master ADD CONSTRAINT fk_devicem_center FOREIGN KEY (regcntr_id)
REFERENCES master.registration_center (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.device_spec DROP CONSTRAINT IF EXISTS fk_dspec_dtyp CASCADE;
ALTER TABLE master.device_spec ADD CONSTRAINT fk_dspec_dtyp FOREIGN KEY (dtyp_code)
REFERENCES master.device_type (code) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;




ALTER TABLE master.machine_master DROP CONSTRAINT IF EXISTS fk_machm_mspec CASCADE;
ALTER TABLE master.machine_master ADD CONSTRAINT fk_machm_mspec FOREIGN KEY (mspec_id)
REFERENCES master.machine_spec (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;



ALTER TABLE master.machine_master DROP CONSTRAINT IF EXISTS fk_machm_zone CASCADE;
ALTER TABLE master.machine_master ADD CONSTRAINT fk_machm_zone FOREIGN KEY (zone_code)
REFERENCES master.zone (code) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;



ALTER TABLE master.machine_master DROP CONSTRAINT IF EXISTS fk_machm_center CASCADE;
ALTER TABLE master.machine_master ADD CONSTRAINT fk_machm_center FOREIGN KEY (regcntr_id)
REFERENCES master.registration_center (id) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;




ALTER TABLE master.machine_spec DROP CONSTRAINT IF EXISTS fk_mspec_mtyp CASCADE;
ALTER TABLE master.machine_spec ADD CONSTRAINT fk_mspec_mtyp FOREIGN KEY (mtyp_code)
REFERENCES master.machine_type (code) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.biometric_attribute DROP CONSTRAINT IF EXISTS fk_bmattr_bmtyp CASCADE;
ALTER TABLE master.biometric_attribute ADD CONSTRAINT fk_bmattr_bmtyp FOREIGN KEY (bmtyp_code)
REFERENCES master.biometric_type (code) MATCH SIMPLE
ON DELETE NO ACTION ON UPDATE NO ACTION;

ALTER TABLE master.zone_user DROP CONSTRAINT IF EXISTS fk_zoneuser_zone CASCADE;
ALTER TABLE master.zone_user ADD CONSTRAINT fk_zoneuser_zone FOREIGN KEY (zone_code)
REFERENCES master.zone (code) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.reg_working_nonworking DROP CONSTRAINT IF EXISTS fk_rwn_daycode CASCADE;
ALTER TABLE master.reg_working_nonworking ADD CONSTRAINT fk_rwn_daycode FOREIGN KEY (day_code)
REFERENCES master.daysofweek_list (code) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;



ALTER TABLE master.reg_working_nonworking DROP CONSTRAINT IF EXISTS fk_rwn_regcntr CASCADE;
ALTER TABLE master.reg_working_nonworking ADD CONSTRAINT fk_rwn_regcntr FOREIGN KEY (regcntr_id)
REFERENCES master.registration_center (id) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.reg_exceptional_holiday DROP CONSTRAINT IF EXISTS fk_regeh_regcntr CASCADE;
ALTER TABLE master.reg_exceptional_holiday ADD CONSTRAINT fk_regeh_regcntr FOREIGN KEY (regcntr_id)
REFERENCES master.registration_center (id) MATCH FULL
ON DELETE NO ACTION ON UPDATE NO ACTION;


ALTER TABLE master.device_master_h DROP CONSTRAINT IF EXISTS pk_devicem_h_id CASCADE;
ALTER TABLE master.device_master_h ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.device_master_h ADD CONSTRAINT pk_devicem_h_id PRIMARY KEY (id,eff_dtimes);

ALTER TABLE master.machine_master_h DROP CONSTRAINT IF EXISTS pk_machm_h_id CASCADE;
ALTER TABLE master.machine_master_h ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.machine_master_h ADD CONSTRAINT pk_machm_h_id PRIMARY KEY (id,eff_dtimes);

ALTER TABLE master.user_detail_h DROP CONSTRAINT IF EXISTS pk_usrdtl_h_id CASCADE;
ALTER TABLE master.user_detail_h ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.user_detail_h ADD CONSTRAINT pk_usrdtl_h_id PRIMARY KEY (id,eff_dtimes);


--------------------------------------------------------------DROP CONSTRAINTS-------------------------------------------

ALTER TABLE master.dynamic_field DROP CONSTRAINT IF EXISTS uk_schfld_name;

ALTER TABLE master.user_detail ALTER COLUMN status_code DROP NOT NULL;
ALTER TABLE master.user_detail ALTER COLUMN name DROP NOT NULL;
ALTER TABLE master.user_detail ALTER COLUMN lang_code DROP NOT NULL;

ALTER TABLE master.user_detail DROP CONSTRAINT IF EXISTS fk_usrdtl_center CASCADE;
ALTER TABLE master.zone_user DROP CONSTRAINT IF EXISTS fk_zoneuser_zone CASCADE;


--------------------------------------------LANG CODE NULLABLE AND CHANGE PK CONSTRAINTS ---------------------------------

ALTER TABLE master.app_authentication_method DROP CONSTRAINT IF EXISTS pk_appauthm_id;
ALTER TABLE master.app_authentication_method ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.app_authentication_method ADD CONSTRAINT pk_appauthm_id PRIMARY KEY (app_id,process_id,role_code,auth_method_code);


ALTER TABLE master.app_role_priority DROP CONSTRAINT IF EXISTS pk_roleprt_id;
ALTER TABLE master.app_role_priority ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.app_role_priority ADD CONSTRAINT pk_roleprt_id PRIMARY KEY (app_id,process_id,role_code);

ALTER TABLE master.applicant_valid_document DROP CONSTRAINT IF EXISTS pk_avaldoc_code;
ALTER TABLE master.applicant_valid_document ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.applicant_valid_document ADD CONSTRAINT pk_avaldoc_code PRIMARY KEY (apptyp_code,doccat_code,doctyp_code);

ALTER TABLE master.authentication_method DROP CONSTRAINT IF EXISTS pk_authm_code;
ALTER TABLE master.authentication_method ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.authentication_method ADD CONSTRAINT pk_authm_code PRIMARY KEY (code);


ALTER TABLE master.biometric_type DROP CONSTRAINT IF EXISTS pk_bmtyp_code;
ALTER TABLE master.biometric_type ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.biometric_type ADD CONSTRAINT pk_bmtyp_code PRIMARY KEY (code);


ALTER TABLE master.device_master DROP CONSTRAINT IF EXISTS pk_devicem_id;
ALTER TABLE master.device_master ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.device_master ADD CONSTRAINT pk_devicem_id PRIMARY KEY (id);


ALTER TABLE master.device_spec DROP CONSTRAINT IF EXISTS pk_dspec_code;
ALTER TABLE master.device_spec ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.device_spec ADD CONSTRAINT pk_dspec_code PRIMARY KEY (id);


ALTER TABLE master.device_type DROP CONSTRAINT IF EXISTS pk_dtyp_code;
ALTER TABLE master.device_type ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.device_type ADD CONSTRAINT pk_dtyp_code PRIMARY KEY (code);

ALTER TABLE master.device_type DROP CONSTRAINT IF EXISTS pk_dtyp_code;
ALTER TABLE master.device_type ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.device_type ADD CONSTRAINT pk_dtyp_code PRIMARY KEY (code);

ALTER TABLE master.machine_master DROP CONSTRAINT IF EXISTS pk_machm_id;
ALTER TABLE master.machine_master ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.machine_master ADD CONSTRAINT pk_machm_id PRIMARY KEY (id);


ALTER TABLE master.machine_spec DROP CONSTRAINT IF EXISTS pk_mspec_code;
ALTER TABLE master.machine_spec ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.machine_spec ADD CONSTRAINT pk_mspec_code PRIMARY KEY (id);


ALTER TABLE master.machine_type DROP CONSTRAINT IF EXISTS pk_mtyp_code;
ALTER TABLE master.machine_type ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.machine_type ADD CONSTRAINT pk_mtyp_code PRIMARY KEY (code);


ALTER TABLE master.reg_exceptional_holiday DROP CONSTRAINT IF EXISTS pk_exceptional_hol;
ALTER TABLE master.reg_exceptional_holiday ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.reg_exceptional_holiday ADD CONSTRAINT pk_exceptional_hol PRIMARY KEY (regcntr_id,hol_date);


ALTER TABLE master.reg_working_nonworking DROP CONSTRAINT IF EXISTS pk_working_nonworking;
ALTER TABLE master.reg_working_nonworking ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.reg_working_nonworking ADD CONSTRAINT pk_working_nonworking PRIMARY KEY (regcntr_id,day_code);


ALTER TABLE master.zone_user DROP CONSTRAINT IF EXISTS pk_tmpltyp_code;
ALTER TABLE master.zone_user ALTER COLUMN lang_code DROP NOT NULL;
ALTER TABLE master.user_detail_h ALTER COLUMN status_code DROP NOT NULL;
ALTER TABLE master.zone_user ADD CONSTRAINT pk_zoneuser PRIMARY KEY (usr_id);
ALTER TABLE master.machine_master ADD CONSTRAINT uq_machm_name UNIQUE (name);
ALTER TABLE master.machine_master ADD CONSTRAINT uq_machm_key_index UNIQUE (key_index);
ALTER TABLE master.machine_master ADD CONSTRAINT uq_machm_skey_index UNIQUE (sign_key_index);


ALTER TABLE master.loc_holiday DROP CONSTRAINT IF EXISTS pk_lochol_id;
ALTER TABLE master.loc_holiday ADD CONSTRAINT pk_lochol_id PRIMARY KEY (holiday_date, location_code, lang_code);

ALTER TABLE master.batch_job_execution_params ALTER COLUMN string_val TYPE varchar(5000) USING string_val::varchar;
ALTER TABLE master.batch_job_execution_params ALTER COLUMN string_val TYPE varchar(5000) USING string_val::varchar;

ALTER TABLE master.user_detail DROP COLUMN uin;
ALTER TABLE master.user_detail DROP COLUMN email;
ALTER TABLE master.user_detail DROP COLUMN mobile;

ALTER TABLE master.user_detail_h DROP COLUMN uin;
ALTER TABLE master.user_detail_h DROP COLUMN email;
ALTER TABLE master.user_detail_h DROP COLUMN mobile;

------------------------------------- module_detail----------------------------------------------------------

TRUNCATE TABLE master.module_detail cascade ;

\COPY master.module_detail (id,name,descr,lang_code,is_active,cr_by,cr_dtimes) FROM './dml/master-module_detail.csv' delimiter ',' HEADER  csv;

----------------------------------------------CREATION OF PERMITTED LOCAL CONFIG -------------------------------------------------------------

\ir ../ddl/master-permitted_local_config.sql

--------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------	ALTER TABLE OF MASTER UI SPEC TABLE----------------------------------------------------------

ALTER TABLE master.ui_spec ALTER COLUMN version TYPE numeric(5,3);
ALTER TABLE master.ui_spec ALTER COLUMN identity_schema_version TYPE numeric(5,3);


-------------------------------------------------------------------------------------------------------------------------------------------
