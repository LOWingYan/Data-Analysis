-- Description: Query shows likelihood of dying in China and the US
SELECT
	location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 AS deaths_percentage
FROM CovidDeaths
WHERE location in ('China','United States')
	and continent is not NULL
ORDER by date, location;


-- Description: Query shows total cases vs. population
SELECT
	location, date, total_cases, population,(CAST(total_cases AS FLOAT)/population)*100 AS infection_rate
FROM CovidDeaths
WHERE continent is not NULL
-- WHERE location in ('China','United States')
ORDER by date, location;


-- Description: Query shows countries with highest Infection Rate compared to population
SELECT
	location, date, population, MAX(total_cases) as highest_infection_count, MAX((CAST(total_cases AS FLOAT)/population)*100) AS infection_rate
FROM CovidDeaths
WHERE continent is not NULL
GROUP by location
ORDER by infection_rate DESC;


-- Description: Query shows countries with highest Death Count
SELECT
	location, MAX(total_deaths) as total_deaths_count
FROM CovidDeaths
WHERE continent is not NULL
GROUP by location
ORDER by total_deaths_count DESC;


-- Description: Query shows continent with highest Death Count
SELECT continent, SUM(total_deaths_count_per_location) as total_deaths_count
FROM(
	SELECT
		continent, location, MAX(total_deaths) as total_deaths_count_per_location
	FROM CovidDeaths
	WHERE continent is not NULL
	GROUP by location
	ORDER by total_deaths_count_per_location DESC
	)
GROUP by continent
ORDER by total_deaths_count DESC;


-- Description: Query shows Global DATA
-- Method 1
SELECT 
	SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, 
	SUM(CAST(new_deaths as FLOAT))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL
ORDER by 1,2;

-- Method 2
SELECT 
	SUM(total_cases_count_per_location) as total_cases, SUM(total_deaths_count_per_location) as total_deaths,
	CAST(SUM(total_deaths_count_per_location) as FLOAT)/SUM(total_cases_count_per_location)*100 as DeathPercentage
FROM(
	SELECT
		continent, location, MAX(total_deaths) as total_deaths_count_per_location, 
		MAX(total_cases) as total_cases_count_per_location
	FROM CovidDeaths
	WHERE continent is not NULL
	GROUP by location
	ORDER by total_deaths_count_per_location DESC
	)
ORDER by total_deaths DESC;


-- Description: Query shows Total population vs Vacciations
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rolling_ppl_vaccinated
FROM CovidDeaths as dea
INNER JOIN CovidVaccinations as vac 
	on dea.location == vac.location and dea.date == vac.date
WHERE dea.continent is not NULL and vac.new_vaccinations is not NULL
ORDER by 2,3;

	
-- Method 1: use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_ppl_vaccinated)
as (
	SELECT 
		dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rolling_ppl_vaccinated
	FROM CovidDeaths as dea
	INNER JOIN CovidVaccinations as vac 
		on dea.location == vac.location and dea.date == vac.date
	WHERE dea.continent is not NULL and vac.new_vaccinations is not NULL
-- 	ORDER by 2,3
	)
SELECT *, (CAST(rolling_ppl_vaccinated as FLOAT)/population)*100 as vacconation_percentage
FROM PopvsVac;

-- Method 2: create Temp Table
DROP Table if EXISTS PopvsVacTable;
CREATE TEMPORARY TABLE PopvsVacTable
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_ppl_vaccinated NUMERIC
);
INSERT INTO PopvsVacTable
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rolling_ppl_vaccinated
FROM CovidDeaths as dea
INNER JOIN CovidVaccinations as vac 
	on dea.location == vac.location and dea.date == vac.date
WHERE dea.continent is not NULL and vac.new_vaccinations is not NULL;

SELECT *, (CAST(rolling_ppl_vaccinated as FLOAT)/population)*100 as vacconation_percentage
FROM PopvsVacTable;


-- Create View to store date for Data Visualization
CREATE VIEW PercentPopulationVaccinated as
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as INT)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as rolling_ppl_vaccinated
FROM CovidDeaths as dea
INNER JOIN CovidVaccinations as vac 
	on dea.location == vac.location and dea.date == vac.date
WHERE dea.continent is not NULL and vac.new_vaccinations is not NULL;