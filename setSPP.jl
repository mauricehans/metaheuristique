# --------------------------------------------------------------------------- #
# Setting the JuMP model of SPP

#Création de la liste sans doublons (Set) des colonnes incompatibles pour chaque colonne
#Construction ligne par ligne pour trouver les conflits
function trouverConflits(A)
  m, n = size(A)
  conflits = [Set{Int}() for _ in 1:n]        

  for i in 1:m
    colonnesLigne = Int[]
    for j in 1:n
      if A[i, j] != 0
        push!(colonnesLigne, j)
      end
    end

    for position1 in 1:(length(colonnesLigne) - 1)
      for position2 in (position1 + 1):length(colonnesLigne)
        colonne1 = colonnesLigne[position1]
        colonne2 = colonnesLigne[position2]
        push!(conflits[colonne1], colonne2)
        push!(conflits[colonne2], colonne1)
      end
    end
  end

  return [sort!(collect(liste)) for liste in conflits]
end

function construireSolutionInitiale(C, conflits)
  n = length(C)
  x = falses(n)
  candidates = trues(n)

  while any(candidates)
    meilleureColonne = 0
    meilleurScore = -Inf

    for j in 1:n
      if candidates[j]
        nbConflitsRestants = count(candidates[k] for k in conflits[j])
        score = C[j] / (1 + nbConflitsRestants)
        if score > meilleurScore
          meilleureColonne = j
          meilleurScore = score
        end
      end
    end

    x[meilleureColonne] = true
    candidates[meilleureColonne] = false
    for k in conflits[meilleureColonne]
      candidates[k] = false
    end
  end

  return x
end

#Aider par chatgpt 6 Luna pour l'écriture de l'algo 
#Test echange 1-1 avec une solution non selectionner
function rechercheLocale11(C, conflits, x)
  solution = copy(x)
  n = length(C)

  while true
    colonneMoinsChere = 0
    for j in 1:n
      if solution[j] && (colonneMoinsChere == 0 || C[j] < C[colonneMoinsChere])
        colonneMoinsChere = j
      end
    end

    amelioration = false
    for q in 1:n
      if solution[q]
        continue
      end

      nbConflitsSelectionnes = 0
      colonneARemplacer = 0
      for k in conflits[q]
        if solution[k]
          nbConflitsSelectionnes += 1
          colonneARemplacer = k
          if nbConflitsSelectionnes > 1
            break
          end
        end
      end

      if nbConflitsSelectionnes > 1
        continue
      end

      if nbConflitsSelectionnes == 0
        colonneARemplacer = colonneMoinsChere
      end

      if colonneARemplacer != 0 && C[q] > C[colonneARemplacer]
        solution[colonneARemplacer] = false
        solution[q] = true
        amelioration = true
        break
      end
    end

    if !amelioration
      break
    end
  end

  return solution
end



function setSPP(C, A)
  m, n = size(A)
  spp = Model()
  @variable(spp, x[1:n], Bin)
  @objective(spp, Max, dot(C, x))
  @constraint(spp , cte[i=1:m], sum(A[i,j] * x[j] for j=1:n) <= 1)
  return spp
end
