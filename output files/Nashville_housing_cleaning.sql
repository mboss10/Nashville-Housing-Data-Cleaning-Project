/************ Checking that I imported the right number of rows from the source file ************/
-- 56,477 expected rows

select count(*) from "Nashville_Housing" nh  

-- also checking that the data looks good by selecting the first 100 rows
select * from "Nashville_Housing" nh  limit 100

/***********    *************/


/************ Standardize SaleDate ************/

-- Let's look at it
select 
	nh."SaleDate" 
from 
	"Nashville_Housing" nh 
	
-- it's in a varchar format, let's change that as we want it in a date format
select 
	to_date("SaleDate", 'dd-mm-yyyy')
from 
	"Nashville_Housing" nh 
	
alter table "Nashville_Housing" 
alter column "SaleDate" type date using to_date("SaleDate", 'dd-mm-yyyy')

/***********    *************/


/************ Clean Property Address data ************/

select
	*
from
	"Nashville_Housing" nh 
where 
	"PropertyAddress" = ''
	
-- a property address should never be empty, 
-- so I am looking into the data to see if we have records with the same ParcelID that have a property address

with cte_id_for_address_empty as (
	select 
		nh."ParcelID"
	from
		"Nashville_Housing" nh 
	where 
	"PropertyAddress" = ''
)
select	
	*
from 
	"Nashville_Housing" nh
inner join
	cte_id_for_address_empty cte on nh."ParcelID" = cte."ParcelID"
order by 
	nh."ParcelID"
	
-- prepare the update with self join query
select 
	nh."UniqueID "
	,nh."PropertyAddress"
	,nh."ParcelID"
	,nh2."UniqueID "
	,nh2."PropertyAddress"
	,nh2."ParcelID"
from
	"Nashville_Housing" nh 
inner join
	"Nashville_Housing" nh2 
on 
	nh."ParcelID" = nh2."ParcelID" 
	and nh."UniqueID " <> nh2."UniqueID " 
where 
	nh."PropertyAddress" = ''

	

-- Now I can update the empty property address with the one on a corresponding matching ParcelID
	
update "Nashville_Housing" nh
set "PropertyAddress" = nh2."PropertyAddress" 
from
	"Nashville_Housing" nh2 
where  
	nh."ParcelID" = nh2."ParcelID" 
	and nh."UniqueID " <> nh2."UniqueID " 
	and nh."PropertyAddress" = ''

/***********    *************/
	

/************ Break out Property Address into address, city ************/

-- use substring and strpos functions to break the property address in address and city fields
select
	"PropertyAddress" 
	,substring("PropertyAddress",1,strpos("PropertyAddress",',')-1) as address
	,substring("PropertyAddress",strpos("PropertyAddress",',')+1) as City
from
	"Nashville_Housing" nh 

	
-- Now let's add the columns to our table
alter table "Nashville_Housing" 
add SplitPropertyAddress varchar(255)

alter table "Nashville_Housing" 
add SplitPropertyCity varchar(255)

update "Nashville_Housing" 
set SplitPropertyAddress = substring("PropertyAddress",1,strpos("PropertyAddress",',')-1)

update "Nashville_Housing" 
set SplitPropertyCity = substring("PropertyAddress",strpos("PropertyAddress",',')+1)

-- quick check
select
	"PropertyAddress" 
	,splitpropertyaddress
	,splitpropertycity
from
	"Nashville_Housing" nh 
	

/***********    *************/
	
/************ Similarly- Break out Owner Address into address, city, state ************/
	
select 
	"OwnerAddress" 
from
	"Nashville_Housing" nh 
	

-- let's split it using split_part() function
select 
	split_part("OwnerAddress",',',1) as owner_address
	,split_part("OwnerAddress",',',2) as owner_city
	,split_part("OwnerAddress",',',3) as owner_state
from
	"Nashville_Housing" nh 
	
-- Now let's add the columns to our table
alter table "Nashville_Housing" 
add owner_address varchar(255)

alter table "Nashville_Housing" 
add owner_city varchar(255)

alter table "Nashville_Housing" 
add owner_state varchar(255)

update "Nashville_Housing" 
set owner_address = split_part("OwnerAddress",',',1)

update "Nashville_Housing" 
set owner_city = split_part("OwnerAddress",',',2)

update "Nashville_Housing" 
set owner_state = split_part("OwnerAddress",',',3)


-- quick check
select
	"OwnerAddress"
	,owner_address
	,owner_city 
	,owner_state 
from
	"Nashville_Housing" nh 
where
	nh."OwnerAddress"<>''

	
/***********    *************/
	
/************ Clean the "SoldAsVacant" field ************/

-- when running the below query we can see sometimes the data is stored as 'Y' or 'N' and sometimes as 'Yes' or 'No'
select 
	"SoldAsVacant"
	,count(1) as total
from
	"Nashville_Housing" nh 
group by	
	"SoldAsVacant"
order by 
	2 desc

-- let's make it consistent

select
	"UniqueID "
	,"SoldAsVacant" 
	,case 
		when "SoldAsVacant" = 'Y' then 'Yes'
		when "SoldAsVacant" = 'N' then 'No'
		else "SoldAsVacant"
	end as fixed_sold_as_vacant
from
	"Nashville_Housing" nh 
	
-- let's update the column
	
update "Nashville_Housing" 
set "SoldAsVacant" = case 
		when "SoldAsVacant" = 'Y' then 'Yes'
		when "SoldAsVacant" = 'N' then 'No'
		else "SoldAsVacant"
	end

-- quick check	
select 
	"SoldAsVacant"
	,count(1) as total
from
	"Nashville_Housing" nh 
group by	
	"SoldAsVacant"
order by 
	2 desc

/***********    *************/
	
/************ look for and remove duplicates ************/
	
-- we have multiple rows for a same combination of ParcelID and SaleDate, which should not be the case if we assume that a same house won't be sold twice on ntthe same day
select
	"ParcelID"
	,"SaleDate" 
	,count(1) as nb_row
from
	"Nashville_Housing" nh 
group by
	"ParcelID"
	,"SaleDate" 
having 
	count(1) > 1

-- writing the query that identifies the duplicates
with cte_dup as (
select 
	*
	,row_number() over (partition by "ParcelID", "SaleDate" order by "UniqueID ") as row_num
from 	
	"Nashville_Housing" nh 
) select
	*
from cte_dup where row_num > 1


-- delete them
with cte_dup as (
select 
	*
	,row_number() over (partition by "ParcelID", "SaleDate" order by "UniqueID ") as row_num
from 	
	"Nashville_Housing" nh 
) 
delete from "Nashville_Housing" nh 
where nh."UniqueID " in (select c."UniqueID " from cte_dup c where row_num > 1)


/***********    *************/
	
/************ Finally create a view to only use the columns that are useful ************/

create or replace view v_nashville_housing as
select
	"UniqueID "
	,"ParcelID"
	,"LandUse"
	,"splitpropertyaddress" as PropertyAddress
	,"splitpropertycity" as PropertyCity
	,"SaleDate"
	,"SalePrice"
	,"LegalReference"
	,"SoldAsVacant"
	,"OwnerName"
	,"owner_address" as OwnerAddress
	,"owner_city" as OwnerCity
	,"owner_state" as OwnerState
	,"Acreage"
	,"LandValue"
	,"BuildingValue"
	,"TotalValue"
	,"YearBuilt"
	,"Bedrooms"
	,"FullBath"
	,"HalfBath"
from
	"Nashville_Housing" nh 
	

-- quick check
select * from v_nashville_housing vnh limit 100
