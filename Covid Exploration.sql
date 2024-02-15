
Select *
From CovidExploration.dbo.CovidDeaths
where continent is not null -- noticed null values in the continent column
order by 3,4

Select *
From CovidExploration.dbo.CovidVaccinations
order by 3,4

-- Selecting data for use 
Select location, date, total_cases, new_cases, total_deaths,population
From CovidExploration..CovidDeaths
order by 1,2

-- Total cases vs Total Deaths
-- Shows likelihood of dying of covid
Select location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
From CovidExploration..CovidDeaths
Where location like '%state%' --to select the word state in the column location
order by 1,2

--Total cases vs Population
--Shows what percentage of population got Covid
Select location, date,population, total_cases, (total_cases/population)*100 AS CasesPercentage
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
order by 1,2 

--Countries with the highest infection rate
Select location, population, MAX(total_cases) AS HighestInfectionCount, Max(total_cases/population)*100 AS PercentagePopulationInfected
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
Group by Location, Population
order by PercentagePopulationInfected desc 

--Countries with highest death count per population
Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
where continent is not null
Group by Location
order by TotalDeathCount desc 

--Now we going for continents not by countries which is Continent with the highest death

Select continent, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
where continent is not null
Group by continent
order by TotalDeathCount desc 

--Below i noticed that where continent is null in location contains a more accurate data for total death in continent
Select location, Max(cast(Total_deaths as int)) as TotalDeathCount
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
where continent is null
Group by location
order by TotalDeathCount desc

--Global numbers

Select SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(new_cases)*100
as DeathPercentage
From CovidExploration..CovidDeaths
--Where location like '%state%' --to select the word state in the column location
where continent is not null
--Group by date
order by 1,2

--Joining both tables

Select *
From CovidExploration..CovidDeaths dea
Join CovidExploration..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

--Looking at total population vs vaccination
--NB Convert converts a dtype and over partition adds by the previos to the next
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RolingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidExploration..CovidDeaths dea
Join CovidExploration..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as

--NB Convert converts a dtype and over partition adds by the previos to the next
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RolingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidExploration..CovidDeaths dea
Join CovidExploration..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


DROP Table if exists #PercentagePopulationVaccinated
Create Table #PercentagePopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
New_Vaccination numeric, 
RollingPeopleVaccinated numeric 
)
Insert into #PercentagePopulationVaccinated 
--NB Convert converts a dtype and over partition adds by the previos to the next
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RolingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidExploration..CovidDeaths dea
Join CovidExploration..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentagePopulationVaccinated--Temp Table

--Creatin my own view for visualization


Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location order by dea.location,
 dea.date) as RolingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From CovidExploration..CovidDeaths dea
Join CovidExploration..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select * from PercentPopulationVaccinated
