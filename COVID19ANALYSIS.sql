--SELECT DATA WHERE LOCATION IS NOT A CONTINENT
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
ORDER BY 1,2;


--TOTAL DEATHS VS TOTAL CASES
--Likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DEATHPERCENTAGE
FROM Covid19Analysis..coviddeaths
WHERE Location like '%India%'
ORDER BY 1,2;


--TOTAL CASES VS POPULATION
SELECT Location, date, total_cases,population, (total_cases/population)*100 AS INFECTEDPERCENTAGE
FROM Covid19Analysis..coviddeaths
WHERE Location like '%India%'
ORDER BY 1,2;


--WHICH COUNTRIES HAVE THE HIGHEST INFECTION RATES
SELECT Location, population,MAX(total_cases) AS HIGHESTINFECTIONCOUNT,(MAX(total_cases)/population)*100 AS INFECTEDPERCENTAGE
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
GROUP BY Location,population
ORDER BY INFECTEDPERCENTAGE DESC;


--WHICH COUNTRIES HAVE THE HIGHEST DEATH COUNT PER POPULATION
SELECT Location, population,MAX(cast(total_deaths as int)) AS HIGHESTDEATHCOUNT,(MAX(total_deaths)/population)*100 AS DEATHPERCENTAGE
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
GROUP BY Location,population
ORDER BY HIGHESTDEATHCOUNT DESC;


--GROUPING BY CONTINENT (DEATH COUNT)
SELECT continent,MAX(cast(total_deaths as int)) AS HIGHESTDEATHCOUNT
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HIGHESTDEATHCOUNT DESC;


--GROUPING BY CONTINENT (INFECTION COUNT)
SELECT continent,MAX(cast(total_cases as int)) AS HIGHESTINFECTIONCOUNT
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HIGHESTINFECTIONCOUNT DESC;


--GLOBAL NUMBERS
SELECT date, location,  SUM(new_cases) AS TOTAL_NEW_CASES, SUM(cast(new_deaths as int)) AS TOTAL_NEW_DEATHS, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 
AS DEATH_PERCENTAGE_WORLDWIDE
FROM Covid19Analysis..coviddeaths
WHERE continent is NOT NULL
and   new_cases > 0
GROUP BY date, location
having SUM(cast(new_deaths as int)) >= 100
ORDER BY date desc, location desc;


SELECT dea.location, MAX(dea.new_cases) AS MAX_NEW_CASES, MIN(dea.date) AS MIN_DATE, count(*) AS COUNT_ROWS, MAX(dea.DATE) AS MAX_DATE, 
	SUM(dea.new_cases) AS TOTAL_NEW_CASES, SUM(cast(dea.new_deaths as int)) AS TOTAL_NEW_DEATHS, 
	(SUM(cast(dea.new_deaths as int))/SUM(dea.new_cases))*100 AS DEATH_PERCENTAGE_WORLDWIDE,
	SUM(CONVERT(int,vacc.new_vaccinations)) AS NEW_VACC
FROM Covid19Analysis..coviddeaths as dea
	JOIN Covid19Analysis..covidvaccinations as vacc ON (dea.location=vacc.location AND
		dea.date=vacc.date)
WHERE dea.continent is NOT NULL
and   dea.new_cases > 0
GROUP BY dea.location
ORDER BY dea.location desc;


SELECT  SUM(new_cases) AS TOTAL_NEW_CASES, SUM(cast(new_deaths as int)) AS TOTAL_NEW_DEATHS, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 
AS DEATH_PERCENTAGE_WORLDWIDE
FROM Covid19Analysis..coviddeaths
ORDER BY 1,2;


--TOTAL POPULATION VS VACCINATIONS

SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,vacc.total_vaccinations FROM 
Covid19Analysis..coviddeaths  dea INNER JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL
ORDER BY total_vaccinations desc;


--Rolling Vaccination Count
--Total for that location and Total vaccinations for that date(Cumulative)
SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,
SUM(ISNULL(CONVERT(int,vacc.new_vaccinations), 0))
	OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) as Vaccination_for_Locn
FROM 
Covid19Analysis..coviddeaths  dea JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL
ORDER BY 2,3 ;


--Vaccinations per day along with Sum of total vaccinations in that location till now
SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,
SUM(ISNULL(CONVERT(int,vacc.new_vaccinations), 0))
	OVER (PARTITION BY dea.location ORDER BY dea.location) as Vaccination_for_Locn
FROM 
Covid19Analysis..coviddeaths  dea JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL
ORDER BY 2,3 ;


--Create Common Table Expression (CTE)
with popvsvac (Continent,Location, Date,Population,New_Vaccination,RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,
SUM(ISNULL(CONVERT(int,vacc.new_vaccinations), 0))
	OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) as Vaccination_for_Locn
FROM 
Covid19Analysis..coviddeaths  dea JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL

)
Select *, (RollingPeopleVaccinated/Population)*100 From popvsvac;



--Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,
SUM(ISNULL(CONVERT(int,vacc.new_vaccinations), 0))
	OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) as Vaccination_for_Locn
FROM 
Covid19Analysis..coviddeaths  dea JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL;

Select *, (RollingPeopleVaccinated/Population)*100 From #PercentPopulationVaccinated;


-- Creating View to store data for visualising vaccinated people percentage
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population,vacc.new_vaccinations,
SUM(ISNULL(CONVERT(int,vacc.new_vaccinations), 0))
	OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) as Vaccination_for_Locn
FROM 
Covid19Analysis..coviddeaths  dea JOIN   Covid19Analysis..covidvaccinations vacc
ON (dea.location=vacc.location AND
dea.date=vacc.date)
WHERE dea.continent is NOT NULL;

Select * from PercentPopulationVaccinated;