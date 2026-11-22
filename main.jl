# =========================================================================== #
# Compliant julia 1.x

# Using the following packages
using JuMP
using LinearAlgebra

include("loadSPP.jl")
include("setSPP.jl")

function executerHeuristique(C, A)
	conflits = trouverConflits(A)
	x0 = construireSolutionInitiale(C, conflits)
	x = rechercheLocale11(C, conflits, x0)
	return (x0=x0, x=x)
end

function executerToutesInstances(repertoireData, cheminRapport)
	fichiers = String[]
	for nom in readdir(repertoireData)
		chemin = joinpath(repertoireData, nom)
		if isfile(chemin) && !startswith(nom, ".")
			push!(fichiers, nom)
		end
	end
	sort!(fichiers)
	isempty(fichiers) && error("Aucun fichier d'instance trouve dans $repertoireData")

	Cchauffe, Achauffe = loadSPP(joinpath(repertoireData, fichiers[1]))
	executerHeuristique(Cchauffe, Achauffe)
	GC.gc()

	open(cheminRapport, "w") do rapport
		println(rapport, "Rapport d'execution de l'heuristique SPP")
		println(rapport, "Temps apres chauffe JIT ; chargement des instances exclu.")
		println(rapport, "Temps mesure : conflits + construction dynamique + recherche locale 1-1.")
		println(rapport, "Nombre d'instances : ", length(fichiers))

		for nom in fichiers
			C, A = loadSPP(joinpath(repertoireData, nom))
			debut = time_ns()
			resultat = executerHeuristique(C, A)
			temps = (time_ns() - debut) / 1e9

			m, n = size(A)
			colonnesInitiales = findall(resultat.x0)
			colonnesFinales = findall(resultat.x)
			valeurInitiale = dot(C, resultat.x0)
			valeurFinale = dot(C, resultat.x)
			realisableInitiale = all(sum(A[i, j] * resultat.x0[j] for j in 1:n) <= 1 for i in 1:m)
			realisableFinale = all(sum(A[i, j] * resultat.x[j] for j in 1:n) <= 1 for i in 1:m)
			@assert realisableInitiale && realisableFinale "Solution non realisable pour $nom"

			println(rapport, "\n============================================================")
			println(rapport, "Instance : ", nom)
			println(rapport, "Dimensions : ", m, " lignes x ", n, " colonnes")
			println(rapport, "Temps heuristique (secondes) : ", temps)
			println(rapport, "Solution initiale :")
			println(rapport, "  Valeur : ", valeurInitiale)
			println(rapport, "  Nombre de colonnes : ", length(colonnesInitiales))
			println(rapport, "  Indices selectionnes : ", colonnesInitiales)
			println(rapport, "  Realisable : ", realisableInitiale)
			println(rapport, "Solution apres echange 1-1 :")
			println(rapport, "  Valeur : ", valeurFinale)
			println(rapport, "  Nombre de colonnes : ", length(colonnesFinales))
			println(rapport, "  Indices selectionnes : ", colonnesFinales)
			println(rapport, "  Realisable : ", realisableFinale)
		end
	end

	return length(fichiers)
end

repertoireData = joinpath(@__DIR__, "Data")
cheminRapport = joinpath(@__DIR__, "resultats_heuristique.txt")
nombreInstances = executerToutesInstances(repertoireData, cheminRapport)
println("Rapport cree : ", cheminRapport)
println("Instances traitees : ", nombreInstances)
