function [optimalPath, totalCost] = customDijkstraPQ(adjMatrix, startNode, endNode)
    numNodes = size(adjMatrix, 1);
    
    % 1. Initialization
    distances = inf(1, numNodes); 
    distances(startNode) = 0; 
    previous = zeros(1, numNodes); 
    pq = [0, startNode]; 
    
    % 2. Iteration
    while ~isempty(pq)
        pq = sortrows(pq, 1); 
        currentDist = pq(1, 1);
        u = pq(1, 2);
        pq(1, :) = []; 
        
        if currentDist > distances(u)
            continue;
        end
        
        if u == endNode
            break;
        end
        
        % 3. Edge Relaxation
        for v = 1:numNodes
            weight = adjMatrix(u, v);
            if weight > 0 && weight ~= inf 
                altDistance = distances(u) + weight; 
                
                if altDistance < distances(v)
                    distances(v) = altDistance;
                    previous(v) = u;
                    pq = [pq; altDistance, v]; 
                end
            end
        end
    end
    
    % 4. Reconstruct the Path
    optimalPath = [];
    totalCost = distances(endNode);
    
    if totalCost == inf
        return; 
    end
    
    curr = endNode;
    while curr ~= 0
        optimalPath = [curr, optimalPath]; 
        curr = previous(curr);
    end
end