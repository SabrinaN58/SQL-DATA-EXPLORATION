
--DATA EXPLORATION COVID IN THE WORLD

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4


SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4

--Je sélectionne les données nécessaires à mon analyse

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

--On veut savoir le nombre total de cas Covid contre le nombre total de mort 
--Cela nous montre le risque de décès si vous contractez le covid dans votre pays ou continent

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Fr%'
ORDER BY 1, 2


--Regardons à présent le nombre total de cas Covid sur le nombre total de la population
--Nous indique le pourcentage de la population qui a contracté le Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as CovidcasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Fr%' AND continent is not null
ORDER BY 1, 2

--Regardons à présent le pays ayant le taux d'infection le plus élevé par rapport au nombre total de la population

SELECT continent,location, population, MAX(total_cases) as Totalcases, max((total_cases/population))*100 as CovidcasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent, location, population
ORDER BY CovidcasesPercentage desc

--Les pays avec le taux de mortalité le plus élevé par population
--Il y a une erreur de type de données sur le fichier la colonne TotalDeath a un type varchar il faut la modifier en int

SELECT location,population, MAX(cast(total_deaths as INT)) as TotalDeathcount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathcount Desc

--Concentrons nous du côté des continents et voir le nombre de décès par continent
--Voyons voir Les continents avec le nombre de décès le plus élevé

SELECT continent, MAX(cast(total_deaths as INT)) as TotalDeathcount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathcount Desc


--A présent nous allons nous pencher sur des nombres globaux afin d'evaluer les nouveaux cas COVID et les nouveaux décès

SELECT date, SUM(new_cases) as total_NewCases, SUM(cast(new_deaths as int)) as total_NewDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2


--Nombre total de nouveaux cas et de nouveaux décès ainsi que le pourcentage de nouveau décès

SELECT SUM(new_cases) as total_NewCases, SUM(cast(new_deaths as int)) as total_NewDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2

--Nous allons à présent voir le nombre total de personnes vaccinées sur le nombre total de la population 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


--Nous avons besoin à présent de creer une CTE pour continuer notre analyse et ainsi définir le pourcentage des personnes vaccinées sur le total de la population de chaque pays 
WITH PopvsVac (continent, location, date, population,new_vaccination, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT * , (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPer
FROM PopvsVac

--Nous allons maintenant créer une table temporaire qui aura le même effet que la CTE 

DROP TABLE IF EXISTS #PercentPeopleVaccinated
CREATE TABLE #PercentPeopleVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date



select *, (RollingPeopleVaccinated/population)*100
FROM #PercentPeopleVaccinated


--Ce qui suit est de créer une vue afin de stocker des données pour une visualisation ultérieure

Create view PercentPeopleVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT * 
FROM PercentPeopleVaccinated