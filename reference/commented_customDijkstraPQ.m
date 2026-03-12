function [optimalPath, totalCost] = customDijkstraPQ(adjMatrix, startNode, endNode)
    % customDijkstraPQ finds the shortest path using a priority queue approach.
    
    numNodes = size(adjMatrix, 1);
    
    % 1. Initialization
    % Create an array to track the shortest distance to each node.
    distances = inf(1, numNodes); 
    distances(startNode) = 0; % Distance to source is 0
    
    % Track the previous node to reconstruct the path later
    previous = zeros(1, numNodes); 
    
    % Our Priority Queue (PQ) will store pairs of: [current_distance, node_number]
    pq = [0, startNode]; 
    
    % 2. Iteration: Loop until the priority queue is empty
    while ~isempty(pq)
        
        % Sort the PQ based on the first column (distance) to act as a Min-Heap.
        % The node with the lowest distance bubbles to the top (row 1).
        pq = sortrows(pq, 1); 
        
        % Extract the node with the minimum distance
        currentDist = pq(1, 1);
        u = pq(1, 2);
        
        % Dequeue (Remove the top element from the PQ)
        pq(1, :) = []; 
        
        % If we found a shorter path to u previously, skip processing
        if currentDist > distances(u)
            continue;
        end
        
        % If we reached the destination, we can optionally stop early
        if u == endNode
            break;
        end
        
        % 3. Edge Relaxation
        % Check all possible neighbors (v) of the current node (u)
        for v = 1:numNodes
            weight = adjMatrix(u, v);
            
            % If there is a valid link (weight > 0 and not infinity)
            if weight > 0 && weight ~= inf 
                altDistance = distances(u) + weight; % Distance(current) + Weight(edge)
                
                % If this new path is shorter, update and push to PQ
                if altDistance < distances(v)
                    distances(v) = altDistance;
                    previous(v) = u;
                    
                    % Push the new distance and node into the Priority Queue
                    pq = [pq; altDistance, v]; 
                end
            end
        end
    end
    
    % 4. Reconstruct the Path
    optimalPath = [];
    totalCost = distances(endNode);
    
    % If the destination is unreachable, return empty
    if totalCost == inf
        return; 
    end
    
    % Work backwards from the destination node using the 'previous' array
    curr = endNode;
    while curr ~= 0
        optimalPath = [curr, optimalPath]; % Prepend to path
        curr = previous(curr);
    end
end