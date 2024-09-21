<img width="1044" alt="ViewResults" src="https://github.com/user-attachments/assets/656f8e9e-c0aa-4f69-90aa-b4a3b6271ea8"># Nashville Housing Data Cleaning Project

## Overview
This project focuses on cleaning and preparing a Nashville housing dataset using SQL. The goal is to transform raw data into a more usable format for analysis, demonstrating various data cleaning techniques.  
The list of all SQL queries used for this project can be found [here](https://github.com/mboss10/Nashville-Housing-Data-Cleaning-Project/blob/main/output%20files/Nashville_housing_cleaning.sql)

## Dataset
The dataset contains information about housing sales in Nashville, including details such as sale date, property address, sale price, and more.  
The dataset file can be found [here](https://github.com/mboss10/Nashville-Housing-Data-Cleaning-Project/blob/main/sources/Nashville%20Housing%20Data%20for%20Data%20Cleaning%20(reuploaded).csv)

I imported the data into a table called `Nashville_Housing` on my local machine Postgres DB.

## Cleaning Process

### 1. Data Validation
- Verified the correct number of rows (56,477) were imported from the source file.

```
select count(*) from "Nashville_Housing" nh
```

<img src="./images/TotalCount.png"></img>

- Performed an initial check of the data by selecting the first 100 rows.

```
select * from "Nashville_Housing" nh  limit 100
```

<img src="./images/InitialCheck.png"></img>

### 2. Standardizing Date Format
- Converted the `SaleDate` column from varchar to date format.

```
alter table "Nashville_Housing" 
alter column "SaleDate" type date using to_date("SaleDate", 'dd-mm-yyyy')
```

<img src="./images/UpdateSaleDateToDateFormat.png"></img>

### 3. Handling Missing Property Addresses
- Identified records with empty `PropertyAddress` fields.

```
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
```

<img src="./images/cteAddressEmpty.png"></img>
  
- Populated missing addresses using data from records with the same `ParcelID`.

```
update "Nashville_Housing" nh
set "PropertyAddress" = nh2."PropertyAddress" 
from
	"Nashville_Housing" nh2 
where  
	nh."ParcelID" = nh2."ParcelID" 
	and nh."UniqueID " <> nh2."UniqueID " 
	and nh."PropertyAddress" = ''
```

<img src="./images/PropertyAddressFilled.png"></img>


### 4. Breaking Out Address Information
- Split `PropertyAddress` into separate columns for address and city.

```
update "Nashville_Housing" 
set SplitPropertyAddress = substring("PropertyAddress",1,strpos("PropertyAddress",',')-1)

update "Nashville_Housing" 
set SplitPropertyCity = substring("PropertyAddress",strpos("PropertyAddress",',')+1)
```

<img src="./images/UpdateSplitPropertyAddress.png"></img>


- Split `OwnerAddress` into separate columns for address, city, and state.

```
update "Nashville_Housing" 
set owner_address = split_part("OwnerAddress",',',1)

update "Nashville_Housing" 
set owner_city = split_part("OwnerAddress",',',2)

update "Nashville_Housing" 
set owner_state = split_part("OwnerAddress",',',3)
```

<img src="./images/UpdateSplitOwnerAddress.png"></img>

  

### 5. Standardizing Field Values
- Standardized the `SoldAsVacant` field to consistently use 'Yes' and 'No' instead of 'Y' and 'N'.

<img src="./images/VacantBefore.png"></img>

```
update "Nashville_Housing" 
set "SoldAsVacant" = case 
		when "SoldAsVacant" = 'Y' then 'Yes'
		when "SoldAsVacant" = 'N' then 'No'
		else "SoldAsVacant"
	end
```

<img src="./images/VacantAfter.png"></img>

### 6. Removing Duplicates
- Identified and removed duplicate entries based on `ParcelID` and `SaleDate`.

```
with cte_dup as (
select 
	*
	,row_number() over (partition by "ParcelID", "SaleDate" order by "UniqueID ") as row_num
from 	
	"Nashville_Housing" nh 
) 
delete from "Nashville_Housing" nh 
where nh."UniqueID " in (select c."UniqueID " from cte_dup c where row_num > 1)
```

<img src="./images/DeleteDuplicates.png"></img>

### 7. Creating a Clean View
- Created a view `v_nashville_housing` that includes only the relevant and cleaned columns.
  
```
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
```

<img src="./images/ViewResults.png"></img>



## SQL Techniques Used
- Data type conversion
- String manipulation (SUBSTRING, STRPOS, SPLIT_PART)
- Self joins for data population
- CASE statements
- Window functions (ROW_NUMBER)
- CTEs (Common Table Expressions)
- View creation

## Conclusion
This project demonstrates various SQL data cleaning techniques, preparing the Nashville housing dataset for further analysis. The cleaned data is more consistent, properly formatted, and free of duplicates, making it suitable for accurate insights and reporting.

## Next Steps
- Perform exploratory data analysis on the cleaned dataset.
- Create visualizations to better understand housing trends in Nashville.
- Develop predictive models for housing prices using the cleaned data.
