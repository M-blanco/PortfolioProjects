
--Select * 
--FROM PortfolioProject..CovidDeath
--order by 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccination
--order by 3,4

--Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
WHERE location like '%World%'
order by 1,2

-- Looking at Total Cases vs Total Deaths (Problem with non dividable nvarchar variable solved with CAST)
-- Shows likelihood of dying if you contract Covid in your country (Spain)
Select Location, date, total_cases, total_deaths, (CAST(total_deaths as float)/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeath
WHERE location like '%Spain%'
order by 1,2

--Looking at Local Cases Vs Population
--Shows what percentaje of population got Covid
Select Location, date,population, total_cases, (CAST(total_cases as float)/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
WHERE location like '%Spain%'
order by 1,2

--Looking at countries with highest infection rate compared to Population
Select Location,population, MAX(total_cases) as HigestInfectionCount, 
(CAST(Max(total_cases) as float)/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Group by location, population
order by PercentPopulationInfected desc


--Showing Death count by continents
Select continent, MAX(CAST(ROUND(total_deaths,1) as INT)) as TotalDeathCount 
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Group by continent
order by TotalDeathCount desc

--Vamos a quitar los decimales de la columna total death para poder pasarlo a valor int
UPDATE PortfolioProject..CovidDeath
SET total_deaths = CONVERT(FLOAT, total_deaths)

--Showing countries with the highest Deaths
Select Location, MAX(CAST(total_deaths as float)) as TotalDeathCount
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Group by location
order by TotalDeathCount desc

--Showing Countries with Highest Death Count per Population
Select Location,population, MAX(CAST(total_deaths as float)) as TotalDeathCount, 
(MAX(CAST(total_deaths as float))/population)*100 as PercentPopulationDeath
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Group by location, population
order by PercentPopulationDeath desc



--LET´S LOOK AT THE DATA DISTRIBUTION BY CONTINENTS


--Showing Death count by continents
Select continent, MAX(CAST(ROUND(total_deaths,1) as INT)) as TotalDeathCount 
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Group by continent
order by TotalDeathCount desc


--Showing continent with the highest death count per population
Select continent,population, Max(CAST(total_deaths as float)) as TotalDeathCount, 
(Max(CAST(total_deaths as float))/population)*100 as PercentPopulationDeath
FROM PortfolioProject..CovidDeath
WHERE continent is not null
Group by continent, population
order by PercentPopulationDeath desc


--GLOBAL NUMBERS


-- Here we Show The Infected/Death realation all around the world at an specific date
Select date, sum(CAST(new_cases as float))as TotalCases, sum (CAST(new_deaths as float))as TotalDeaths, 
100 * SUM(CAST(new_deaths as float)) / NULLIF(SUM(CAST(new_cases as float)), 0) as DeathPercentage --, total_deaths, (CAST(total_deaths as float)/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Where continent is not null
group by date
order by DeathPercentage desc

--Here We Show The Worldwide death percentage
Select sum(CAST(new_cases as float))as TotalCases, sum (CAST(new_deaths as float))as TotalDeaths, 
100 * SUM(CAST(new_deaths as float)) / NULLIF(SUM(CAST(new_cases as float)), 0) as DeathPercentage --, total_deaths, (CAST(total_deaths as float)/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Where continent is not null
--group by date
order by 1,2


--Looking at Total Population Vs Total Vaccinations

--The percentage may exceed 100% due to the second and third dosis applied

--Use Temp Table

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location Nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(CAST(New_Vaccinations as float)) OVER (Partition by dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac
on dea.location = vac.location
and dea.date= vac.date
WHERE dea.continent is not null
--order by 2,3


-- The new vaccunated variable also counts second and third dosis applied as new vaccinated,
-- due to this situation, the percentage of VaccinatedPeople may exceed 100%, thats why we have made two diferent selections,
-- in the first one the VaccinationPercentage can exceed 100%, in the second, once it gets to 100% it doesnt exceed that number.

--Can exceed 100% percent
Select *, (RollingPeopleVaccinated/Population) *100 as VaccinationPercentage
FROM #PercentPopulationVaccinated
order by 2,3

--Cant exceed 100% 
Select *, 
CASE 
        WHEN (RollingPeopleVaccinated / Population) > 1 
        THEN 100 
        ELSE (RollingPeopleVaccinated / Population) * 100 
    END AS VaccinationPercentage
FROM #PercentPopulationVaccinated
order by 2,3






--USE CTE
With PopVsVac (continent, location, date, population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(CAST(New_Vaccinations as float)) OVER (Partition by dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac
on dea.location = vac.location
and dea.date= vac.date
WHERE dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population) *100
FROM PopVsVac

 



 -- Creating View to Store Data for later Visualization
 -- We will be looking at The Percentage of death, infected and Vaccinated people by each country
 
 Create View PercentPopulationDeath as
Select Location,population, MAX(CAST(total_deaths as float)) as TotalDeathCount, 
(MAX(CAST(total_deaths as float))/population)*100 as PercentPopulationDeath
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Group by location, population
--order by PercentPopulationDeath desc


Create View PercentPopulationInfected as
Select Location,population, MAX(total_cases) as HigestInfectionCount, 
(CAST(Max(total_cases) as float)/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeath
--WHERE location like '%Spain%'
Group by location, population
--order by PercentPopulationInfected desc

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(CAST(New_Vaccinations as float)) OVER (Partition by dea.location Order by dea.location,
dea.date) as RollingPeopleVaccinated 
FROM  PortfolioProject..CovidDeath dea
Join PortfolioProject..CovidVaccination vac
on dea.location = vac.location
and dea.date= vac.date
WHERE dea.continent is not null
--order by 2,3

SELECT dea.location, dea.date, dea.population,total_vaccinations, new_vaccinations
FROM CovidVaccination vac
Join CovidDeath dea
On vac.location = dea.location
WHERE dea.location like '%Germany%'
Order by dea.date
