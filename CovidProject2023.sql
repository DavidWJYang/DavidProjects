USE CovidProject;
SElECT * FROM Covid_Death;

-- 1. Total Cases Versus Total Deaths, Shows likelihood of dying if caught Covid
SELECT location, occurance, total_cases, total_deaths, (total_deaths/total_cases) * 100 as Death_Rate 
FROM COVID_Death
WHERE location like '%Canada%';

-- 2. Total Cases Versus Population, % of population that caught covid
SELECT location, occurance, total_cases, population, (total_cases/population) * 100 as Chance_of_catching_covid
FROM Covid_Death
WHERE location like '%Canada%';

-- 3. New Cases Versus Population, % of population catching covid recently 2022-01-01 and more recently
SELECT location, occurance, new_cases, population, (new_cases/population) * 100 as new_cases_perecentage
FROM Covid_Death
WHERE location like '%Canada%' AND Occurance > '2022-01-01'; 

-- 4. Countries with highest infection rate versus population
SELECT location, population, max(total_cases) as MAXInfected, Max((total_cases/population)) * 100 as 
Percent_population_infected 
FROM Covid_Death
WHERE location != 'World' OR location != 'Europe' OR location != 'North America' OR location != 'European Union' OR 
location != 'South America' OR location != 'Asia' OR location != 'Africa' OR location != 'Oceania' OR location != 'International'
GROUP BY location, population
ORDER BY percent_population_infected desc;

-- 4. WITH DATE
SELECT location, occurance, population, max(total_cases) as MAXInfected, Max((total_cases/population)) * 100 as 
Percent_population_infected 
FROM Covid_Death
WHERE location != 'World' OR location != 'Europe' OR location != 'North America' OR location != 'European Union' OR 
location != 'South America' OR location != 'Asia' OR location != 'Africa' OR location != 'Oceania' OR location != 'International'
GROUP BY location, population, occurance;

-- 5. Countries with higest death count per population 
SELECT location, max(total_deaths) as TotalDeathCount
FROM Covid_Death
WHERE continent IS NOT NULL
GROUP BY location 
ORDER BY TotalDeathCount desc;

-- 6. Continents with highest death count per population
SELECT location, max(total_deaths) as TotalDeathCount
FROM Covid_Death
WHERE location = 'World' OR location = 'Europe' OR location = 'North America' OR location = 'European Union' OR 
location = 'South America' OR location = 'Asia' OR location = 'Africa' OR location = 'Oceania' OR location = 'International'
GROUP BY location
ORDER BY TotalDeathCount desc;


-- Global Stats

-- 7. Globally, how many new cases per day, how many new deaths per day, ratio of new cases per day and new deaths per day
SELECT Occurance, sum(new_cases), sum(new_deaths), (sum(new_deaths)/sum(new_cases)) * 100 as DeathPercentage
FROM Covid_Death
WHERE location != 'World' OR location != 'Europe' OR location != 'North America' OR location != 'European Union' OR 
location != 'South America' OR location != 'Asia' OR location != 'Africa' OR location != 'Oceania' OR location != 'International'
GROUP BY Occurance;

-- 8. Global Death Percentage
SELECT sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases)) * 100 as DeathPercentage
FROM Covid_Death
WHERE location != 'World' OR location != 'Europe' OR location != 'North America' OR location != 'European Union' OR 
location != 'South America' OR location != 'Asia' OR location != 'Africa' OR location != 'Oceania' OR location != 'International'
;

-- To Join Covid19Vac Table and Covid19Death Table
SELECT * 
FROM Covid_Death
JOIN Covid_Vaccinations
	ON Covid_Death.location = Covid_Vaccinations.location
    and Covid_Death.Occurance = Covid_Vaccinations.Occurance;
    
-- 10. Globally, Total Population versus Vaccination
WITH PopvsVac (continent, location, occurance, population, new_vaccinations, RollingTotalVacs) as (
SELECT dea.continent, dea.location, dea.occurance, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.occurance) as RollingTotalVacs
FROM Covid_Death dea
JOIN Covid_Vaccinations vac
	ON dea.location = vac.location
    and dea.Occurance = vac.Occurance
WHERE dea.location != 'World' OR dea.location != 'Europe' OR dea.location != 'North America' OR dea.location != 'European Union' OR 
dea.location != 'South America' OR dea.location != 'Asia' OR dea.location != 'Africa' OR dea.location != 'Oceania' OR dea.location != 'International'
or vac.location != 'World' OR vac.location != 'Europe' OR vac.location != 'North America' OR vac.location != 'European Union' OR 
vac.location != 'South America' OR vac.location != 'Asia' OR vac.location != 'Africa' OR vac.location != 'Oceania' OR vac.location != 'International'
) SELECT *, (RollingTotalVacs/Population) * 100 
FROM PopvsVac;

WITH PopvsVac (continent, location, occurance, population, new_vaccinations, RollingTotalVacs) as (
SELECT dea.continent, dea.location, dea.occurance, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.occurance) as RollingTotalVacs
FROM Covid_Death dea
JOIN Covid_Vaccinations vac
	ON dea.location = vac.location
    and dea.Occurance = vac.Occurance
) SELECT *, (RollingTotalVacs/Population) * 100 
FROM PopvsVac;

-- TEMP Table

DROP TABLE if exists PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
continent VARCHAR (100),
location VARCHAR (100),
occurance DATE,
population INT,
New_Vaccination INT,
RollingTotalVacs int);

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.occurance, dea.population, vac.new_vaccinations, sum(vac.new_vaccinations) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.occurance) as RollingTotalVacs
FROM Covid_Death dea
JOIN Covid_Vaccinations vac
	ON dea.location = vac.location
    and dea.Occurance = vac.Occurance;
SELECT *, (RollingTotalVacs/Population) * 100 
FROM PercentPopulationVaccinated;

-- Creating View for Tableau Use
CREATE VIEW NewCasesPerDayVerusNewDeathsPerDay as
SELECT Occurance, sum(new_cases), sum(new_deaths), (sum(new_deaths)/sum(new_cases)) * 100 as DeathPercentage
FROM Covid_Death
WHERE location != 'World' OR location != 'Europe' OR location != 'North America' OR location != 'European Union' OR 
location != 'South America' OR location != 'Asia' OR location != 'Africa' OR location != 'Oceania' OR location != 'International'
GROUP BY Occurance;

Select * FROM newcasesperdayverusnewsdeathsperday;

CREATE VIEW ContinentTotalDeath as
SELECT location, max(total_deaths) as TotalDeathCount
FROM Covid_Death
WHERE location = 'World' OR location = 'Europe' OR location = 'North America' OR location = 'European Union' OR 
location = 'South America' OR location = 'Asia' OR location = 'Africa' OR location = 'Oceania' OR location = 'International'
GROUP BY location
ORDER BY TotalDeathCount desc;

SELECT * FROM ContinentTotalDeath;

CREATE VIEW CountryInfectionRate as
SELECT location, population, max(total_cases) as MAXInfected, Max((total_cases/population)) * 100 as 
Percent_population_infected 
FROM Covid_Death
GROUP BY location, population
ORDER BY percent_population_infected desc;

