/* ******************************************************************************************************************************
 * Scenario 4: Build a special bridge table for the organization structure (using Closure table approach)
 * 
 * Inputs:
 *   2 target tables: 
 *     1) dim_employee (already prepolulated)
 *     2) bridge_employee_hierachy table where hierarchical data should be populate according to Closure table approach  
 * 
 *   1 input table:
 *     1) stg_employee table where each record contains parent_id
 *     
 ****************************************************************************************************************************** */

------------------------------------------------------------------------------------------------------------------
-- Initialization (target tables)
------------------------------------------------------------------------------------------------------------------
drop table if exists dim_employee;
create table dim_employee(
    employee_sk serial primary key,
    employee_bk varchar(255),
    full_name  varchar(255)
);
truncate table dim_employee;
insert into dim_employee(employee_bk, full_name) 
values 
('uk100', 'Lori Smith'),
('uk101', 'Ivan Kohut'),
('uk102', 'Oksana Lysytsia'),
('uk103', 'Iryna Vovk'),
('uk104', 'Mag Smith'),
('uk105', 'Ivanka Kohut'),
('uk106', 'Leyla Lysytsia'),
('uk107', 'Olesia Vovk'),
('uk108', 'John Smith'),
('uk109', 'Ivan Piven'),
('uk110', 'Oksana Baran'),
('uk111', 'Iryna Zayets');

drop table if exists bridge_employee_hierachy;
create table bridge_employee_hierachy(
    ancestor_employee_sk int not null,
    descendant_employee_sk int not null,
    depth_from_parent int,
    is_leaf boolean,
    primary key (ancestor_employee_sk,descendant_employee_sk)
);


------------------------------------------------------------------------------------------------------------------
-- Initialization (target tables)
------------------------------------------------------------------------------------------------------------------
drop table if exists stg_employee;
create table stg_employee(
    employee_bk varchar(255) not null primary key,
    full_name  varchar(255),
    parent_bk varchar(255)
);

truncate table stg_employee;
insert into stg_employee(employee_bk, full_name, parent_bk) 
values 
('uk100', 'Lori Smith',null),
('uk101', 'Ivan Kohut','uk100'),
('uk102', 'Oksana Lysytsia','uk100'),
('uk103', 'Iryna Vovk','uk101'),
('uk104', 'Mag Smith','uk101'),
('uk105', 'Ivanka Kohut','uk102'),
('uk106', 'Leyla Lysytsia','uk102'),
('uk107', 'Olesia Vovk','uk104'),
('uk108', 'John Smith','uk104'),
('uk109', 'Ivan Piven','uk107'),
('uk110', 'Oksana Baran','uk108'),
('uk111', 'Iryna Zayets','uk109');


/* ******************************************************************************************************************************
 * Exersize #4 (build hierarchy bridge table):
 * Prepare a SQL script (sequence of SQL statements) to build the bridge_employee_hierachy table according to closure table algorithm
 ****************************************************************************************************************************** */

with recursive hierarchy_entries as (
    -- Root.
    select
        employee_bk as ancestor_employee_bk,
        employee_bk as descendant_employee_bk,
        0 as depth_from_parent,
        false as is_leaf
    from stg_employee
    where parent_bk is null

    union all

    -- Recursive.
    select
        hierarchy_entries.descendant_employee_bk as ancestor_employee_bk,
        stg_employee.employee_bk as descendant_employee_bk,
        hierarchy_entries.depth_from_parent + 1 as depth_from_parent,
        not exists(select 1 from stg_employee as tmp where tmp.parent_bk = stg_employee.employee_bk) as is_leaf
    from stg_employee
    inner join hierarchy_entries on stg_employee.parent_bk = hierarchy_entries.descendant_employee_bk
)

insert into bridge_employee_hierachy(ancestor_employee_sk, descendant_employee_sk, depth_from_parent, is_leaf)
select
    ancestor.employee_sk,
    descendant.employee_sk,
    hierarchy_entries.depth_from_parent,
    hierarchy_entries.is_leaf
from hierarchy_entries
inner join dim_employee as ancestor on hierarchy_entries.ancestor_employee_bk = ancestor.employee_bk
inner join dim_employee as descendant on hierarchy_entries.descendant_employee_bk = descendant.employee_bk;
