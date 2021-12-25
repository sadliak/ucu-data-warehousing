/* ******************************************************************************************************************************
 * 
 * Scenario 1: SCD1 and SCD2 incremental data processing
 *     
 ****************************************************************************************************************************** */

------------------------------------------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------------------------------------------
drop table if exists dim_customer;
create table dim_customer
(
    customer_sk  serial primary key,
    customer_bk  varchar(255),
    full_name    varchar(255), -- SCD1 attribure
    country      varchar(255), -- SCD2 attribure
    state_region varchar(255), -- SCD2 attribure
    valid_from   timestamp,
    valid_to     timestamp
);
truncate table dim_customer;
insert into dim_customer(customer_bk, full_name, country, state_region, valid_from, valid_to)
values ('us101', 'Lori Smith', 'US', 'Texas', '1900-01-01', '9999-12-31 23:59:59'),
       ('uk101', 'Ivan Kohut', 'Ukraine', 'Lviv', '1900-01-01', '2020-10-31 23:59:59'),
       ('uk101', 'Ivan Kohut', 'Ukraine', 'Kyiv', '2020-11-01', '9999-12-31 23:59:59'),
       ('uk102', 'Oksana Lysytsia', 'Ukraine', 'Ternopil', '1900-01-01', '9999-12-31 23:59:59'),
       ('uk103', 'Iryna Vovk', 'Ukraine', 'Ivano-Frankivsk', '1900-01-01', '9999-12-31 23:59:59');


drop table if exists stg_customer;
create table stg_customer
(
    customer_bk  varchar(255) primary key,
    full_name    varchar(255),
    country      varchar(255),
    state_region varchar(255)
);
truncate table stg_customer;
insert into stg_customer(customer_bk, full_name, country, state_region)
values ('us101', 'Lorelei Smith', 'US', 'Texas'),
       ('us102', 'Chris Black', 'US', 'California'),
       ('uk101', 'Ivan Kohut-Baran', 'Ukraine', 'Irpin'),
       ('uk102', 'Oksana Lysytsia-Vovk', 'Ukraine', 'Ternopil'),
       ('uk103', 'Iryna Vovk', 'Ukraine', 'Ivano-Frankivsk');


/* ******************************************************************************************************************************
 * Exersize #1:
 * Prepare a SQL script (sequence of SQL statements) to implement the merging of the stg_customer (increment of the customer data) 
 * into the target dim_customer dimension table  
 ****************************************************************************************************************************** */
begin;

-- Update SCD1 full_name column.
update dim_customer
set full_name = stg_customer.full_name
from stg_customer
where dim_customer.customer_bk = stg_customer.customer_bk;

-- Insert new & update existing records with SCD2 columns changed.
with dc_last_versions as (
    select *
    from dim_customer
    where valid_to = '9999-12-31 23:59:59'
),
dc_new_versions as (
    select stg_customer.*,
           dc_last_versions.customer_sk as last_version_sk
    from stg_customer
    left join dc_last_versions on dc_last_versions.customer_bk = stg_customer.customer_bk
    where
        -- Existing customer and SCD2 columns differ with the last version ones.
        (dc_last_versions.customer_sk is not null and
            (stg_customer.country != dc_last_versions.country or
             stg_customer.state_region != dc_last_versions.state_region)) or
        -- New customer.
        dc_last_versions.customer_sk is null
),

-- Update last version as part of CTE.
dc_last_version_updates as (
    update dim_customer
    set valid_to = (now() - INTERVAL '00:00:01')
    from dc_new_versions
    where dim_customer.customer_sk = dc_new_versions.last_version_sk
    returning dim_customer.customer_sk
)

insert into dim_customer(customer_bk, full_name, country, state_region, valid_from, valid_to)
select dc_new_versions.customer_bk,
       dc_new_versions.full_name,
       dc_new_versions.country,
       dc_new_versions.state_region,
       now(),
       '9999-12-31 23:59:59'
from dc_new_versions;

commit;
