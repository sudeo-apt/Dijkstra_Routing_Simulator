% PHASE 1: Build the Static Network (The Map)

% 1. Define the Cost (Adjacency) Matrix for 10 nodes.
% Rows and columns represent Routers 1 through 10.
costMatrix = [
     0,  15,   0,   0,  20,   0,   0,   0,   0,  50; % R1
    15,   0,  10,   0,   0,  25,   0,   0,   0,   0; % R2
     0,  10,   0,  12,   0,   0,  30,   0,   0,   0; % R3
     0,   0,  12,   0,  18,   0,   0,  15,   0,   0; % R4
    20,   0,   0,  18,   0,  10,   0,   0,  40,   0; % R5
     0,  25,   0,   0,  10,   0,  14,   0,   0,   0; % R6
     0,   0,  30,   0,   0,  14,   0,   8,   0,  22; % R7
     0,   0,   0,  15,   0,   0,   8,   0,  16,   0; % R8
     0,   0,   0,   0,  40,   0,   0,  16,   0,  10; % R9
    50,   0,   0,   0,   0,   0,  22,   0,  10,   0  % R10
];

% 2. Create the Graph Object
% We use 'graph' to create an undirected graph with bidirectional links.
G = graph(costMatrix); 

% 3. Plot the Network
% Create a new figure window
figure; 

% Plot the graph with some basic styling
% 'Layout', 'force' spreads the nodes out nicely so they don't overlap
% Update the NodeLabels to include R1 through R10
p = plot(G, 'Layout', 'force', 'NodeLabel', {'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8', 'R9', 'R10'});
% 4. Make it visually clear
p.MarkerSize = 8;
p.NodeColor = 'b'; % Make the routers blue
title('Phase 1: 5-Node Network Topology');

% 5. Display the Edge Weights
% This grabs the weights we defined in our matrix and prints them on the lines
labeledge(p, 1:numedges(G), G.Edges.Weight);

disp('Phase 1 Complete: Network plotted successfully.');

% PHASE 2: Implement Static Routing

% Define Source and Destination for the 10-node network
sourceNode = 1;
destNode = 8;

% 2. Calculate the Shortest Path
% MATLAB's built-in function uses Dijkstra's algorithm to find the lowest cost path.
% It returns the sequence of nodes (the path) and the total cost of that route.
[optimalPath, totalCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);

% 3. Display the Results in the Command Window
fprintf('Finding optimal path from R%d to R%d...\n', sourceNode, destNode);
disp(['Nodes in optimal path: ', num2str(optimalPath)]);
disp(['Total path cost: ', num2str(totalCost)]);

% 4. Highlight the Path on the Plot
% We will make the edges of the optimal path green and thicker so it stands out.
highlight(p, optimalPath, 'EdgeColor', 'g', 'LineWidth', 3);
title(['Phase 2: Shortest Path from R', num2str(sourceNode), ' to R', num2str(destNode)]);

disp('Phase 2 Complete: Optimal path calculated and highlighted.');

% PHASE 3 & 4: Interactive Dynamic Routing and Self-Healing

disp(' ');
disp('==================================================');
disp('   INTERACTIVE NETWORK SIMULATION INITIALIZED');
disp('==================================================');

% This while loop keeps the simulation running until you press 0
while true
    disp(' ');
    disp('Choose an action to test network resilience:');
    disp('1. Simulate Traffic Congestion (Increase Link Cost)');
    disp('2. Simulate Link Failure (Break a Link)');
    disp('0. Exit Simulation');
    
    choice = input('Enter your choice (0/1/2): ');
    
    % Exit condition
    if choice == 0
        disp('Exiting simulation... Have a Great Day!!');
        break;
    end
    
    % Handle valid interactions (1 or 2)
    if choice == 1 || choice == 2
        disp(' ');
        % Ask the user which link to modify
        nodeA = input('Enter the first router of the link (Node A, 1-10): ');
        nodeB = input('Enter the second router of the link (Node B, 1-10): ');
        
        % Error handling: Ensure nodes are valid
        if nodeA < 1 || nodeA > 10 || nodeB < 1 || nodeB > 10 || nodeA == nodeB
            disp('ERROR: Invalid routers entered. Please try again.');
            continue; % Skips the rest of the loop and starts over
        end
        
        % Error handling: Check if the link actually exists in our graph
        edgeIdx = findedge(G, nodeA, nodeB);
        if edgeIdx == 0
            disp('ERROR: There is no direct link between these routers. Try again.');
            continue;
        end
        
        % Apply the specific logic based on user choice
        if choice == 1
            % Traffic Jam Logic: Dynamic updates based on simulated traffic density [cite: 9]
            newWeight = input('Enter the new high traffic cost (e.g., 50, 100): ');
            statusMsg = 'CONGESTION DETECTED';
            lineStyle = '-';
            edgeLabel = num2str(newWeight);
        elseif choice == 2
            % Self-Healing Logic: Assigning an infinite weight effectively removes it [cite: 70]
            newWeight = inf; 
            statusMsg = 'CRITICAL LINK FAILURE';
            lineStyle = '--';
            edgeLabel = '\infty';
        end
        
        disp(['Processing: ', statusMsg, ' on link R', num2str(nodeA), '-R', num2str(nodeB), '...']);
        
        % 1. Update the Matrices (Must update both directions for symmetric links)
        costMatrix(nodeA, nodeB) = newWeight;
        costMatrix(nodeB, nodeA) = newWeight;
        
        % Update the visual Graph object's weight as well
        G.Edges.Weight(edgeIdx) = newWeight;
        
        % 2. Recalculate using your custom priority queue Dijkstra
        % Start the stopwatch right before the algorithm runs
        tic; 
        
        [newPath, newCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);
        
        % Stop the stopwatch and save the elapsed time
        elapsedTime = toc; 
        
        % Convert the time from seconds to milliseconds for better readability
        convergenceTimeMs = elapsedTime * 1000;
        
        % 3. Update the Plot
        % Reset all lines back to default blue first to clear old highlights
        p.EdgeColor = [0 0.4470 0.7410];
        p.LineWidth = 1;
        p.LineStyle = '-';
        
        % Update the number/symbol displayed on the specific link
        labeledge(p, edgeIdx, edgeLabel);
        
        % Failed or congested links are shown in red with higher thickness [cite: 79]
        highlight(p, nodeA, nodeB, 'EdgeColor', 'r', 'LineWidth', 4, 'LineStyle', lineStyle);
        
        % Check if a path still exists
        if isempty(newPath) || newCost == inf
            disp('NETWORK ISOLATED: No alternate paths available to the destination.');
            title('Phase 4: Network Failure. Destination Unreachable.');
        else
            % Optimal paths are highlighted in green
            highlight(p, newPath, 'EdgeColor', 'g', 'LineWidth', 3);
            title([statusMsg, ' - Self-Healed. New Path Cost: ', num2str(newCost)]);
            
            % Print results to the Command Window
            disp('Success! Traffic Diverted.');
            disp(['New optimal path: ', num2str(newPath)]);
            disp(['New total path cost: ', num2str(newCost)]);
            
            % Print the convergence time
            fprintf('Algorithm Convergence Time: %.4f milliseconds\n', convergenceTimeMs);
        end
        
        drawnow; % Force the figure window to update instantly
        
    else
        disp('Invalid choice. Please type 0, 1, or 2 and press Enter.');
    end
end