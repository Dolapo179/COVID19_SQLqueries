
SELECT *
FROM CovidDeaths;

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2;

-- TOTAL CASES VS TOTAL DEATH. The percentage of death per location.
-- shows likelihood of death if a person contact covid in a country
SELECT location, date, total_cases, total_deaths, 
CAST((CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS DECIMAL(10,2)) AS death_percentage
FROM CovidDeaths
WHERE location LIKE '%Kingdom'
ORDER BY 1, 2;

--- total cases vs population
---shows percentage of people with Covid in that population
SELECT location, date, population, total_cases,
(CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS percent_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

---country with the highest infection rate compare to location
SELECT location, population, Max(total_cases) AS HighestInfectionCount,
Max((CAST(total_cases AS FLOAT)/CAST(population AS FLOAT)))*100 AS percent_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected desc;

---countries with highest death count per population
SELECT location, SUM(total_deaths) AS highest__total_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_total_death desc;

SELECT location, MAX(total_deaths) AS highest__death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death desc;

---By Continent
---continent with the highest death count
SELECT continent, SUM(total_deaths) AS highest_total_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_total_death desc;

SELECT continent, MAX(total_deaths) AS highest_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death desc;

--- Global Numbers
SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, 
CAST(SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT))*100 AS DECIMAL(10,2)) AS global_death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

---overall death percentage
SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, 
CAST(SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT))*100 AS DECIMAL(10,2)) AS global_death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


----Joins
SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date

---- Total Population and Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

---Total Vaccination per day Partition by location. 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

---Total population vs. total vaccinated
WITH population_per_vaccinated (continent, location, date, population, new_vaccinations, total_vaccinated)
AS 
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinated
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date
	WHERE dea.continent IS NOT NULL
	)
SELECT *, CAST((CAST(total_vaccinated AS FLOAT)/CAST(population AS FLOAT))* 100 AS DECIMAL(10,2)) AS percent_population_per_vaccinated
FROM population_per_vaccinated;
	
--- TEMP TABLE

DROP TABLE IF EXISTS #percent_population_per_vaccinated
CREATE TABLE #percent_population_per_vaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vaccinated numeric
)
INSERT INTO #percent_population_per_vaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinated
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date
	WHERE dea.continent IS NOT NULL
SELECT *, CAST((CAST(total_vaccinated AS FLOAT)/CAST(population AS FLOAT))* 100 AS DECIMAL(10,2)) AS percent_population_per_vaccinated
FROM  #percent_population_per_vaccinated;

--View

CREATE VIEW percent_population_per_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinated
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date =vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY 2,3;