clc;
close all;
clear all;
% PHASE 1: Dynamic Random Network Generator
disp('--- NETWORK INITIALIZATION ---');
numNodes = input('Enter the number of routers for the simulation : ');

% 1. Initialize empty matrices
costMatrix = zeros(numNodes);
bwMatrix = zeros(numNodes);

% 2. Guarantee a base connection (Spanning Tree / Line) so the graph is never broken
for i = 1:(numNodes-1)
    w = randi([10, 50]); % Random cost between 10 and 50
    costMatrix(i, i+1) = w;
    costMatrix(i+1, i) = w;
    
    % Random bandwidth for baseline: 50 or 100 Mbps
    bw = 50 * randi([1,2]); 
    bwMatrix(i, i+1) = bw; bwMatrix(i+1, i) = bw;
end

% 3. Add random cross-links (The "Mesh" effect)
for i = 1:numNodes
    for j = (i+2):numNodes % Skip adjacent nodes
        if rand() < 0.3 % 30% chance of a random link existing
            w = randi([15, 100]); % Random high cost
            costMatrix(i, j) = w;
            costMatrix(j, i) = w;
            
            % Random bandwidth: 10, 50, or 100 Mbps
            bw_opts = [10, 50, 100];
            bw = bw_opts(randi(3));
            bwMatrix(i, j) = bw; bwMatrix(j, i) = bw;
        end
    end
end

% 4. Create the Graph Object
G = graph(costMatrix); 
figure('Name', 'Smart Routing Dashboard', 'NumberTitle', 'off'); 

% Generate dynamic node labels (R1, R2, ..., Rn)
nodeNames = arrayfun(@(x) sprintf('R%d', x), 1:numNodes, 'UniformOutput', false);

% Plot with force layout (MATLAB automatically spaces them out nicely)
p = plot(G, 'Layout', 'force', 'NodeLabel', nodeNames);
p.MarkerSize = 8;
p.NodeColor = 'b'; 
title(['Phase 1: ', num2str(numNodes), '-Node Randomized Network Topology']);

labeledge(p, 1:numedges(G), G.Edges.Weight);
disp('Phase 1 Complete: Randomized Network generated successfully.');

% Set default routing from Node 1 to the Last Node
sourceNode = 1;
destNode = numNodes;

% PHASE 2: Implement Static Routing
sourceNode = 1;
destNode = 8;

[optimalPath, totalCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);

fprintf('Finding optimal path from R%d to R%d...\n', sourceNode, destNode);
disp(['Nodes in optimal path: ', num2str(optimalPath)]);
disp(['Total path cost: ', num2str(totalCost)]);

highlight(p, optimalPath, 'EdgeColor', 'g', 'LineWidth', 3);
title(['Phase 2: Shortest Path from R', num2str(sourceNode), ' to R', num2str(destNode)]);
disp('Phase 2 Complete: Optimal path calculated and highlighted.');

% PHASE 3 & 4: Interactive Dynamic Routing and Self-Healing
disp(' ');

disp('   INTERACTIVE NETWORK SIMULATION INITIALIZED');


while true
    disp(' ');
    fprintf('--- Current Route: R%d to R%d ---\n', sourceNode, destNode);
    disp('Choose an action to test network resilience:');
    disp('1. Simulate Traffic Congestion (Increase Link Cost)');
    disp('2. Simulate Link Failure (Break a Link)');
    disp('3. Change Source and Destination Nodes'); 
    disp('4. Simulate Node Failure (Crash Router)');  
    disp('0. Exit Simulation');
    
    choice = input('Enter your choice (0/1/2/3/4): ');
    
    if choice == 0
        disp('Exiting simulation... Have a Great Day!!');
        break;
    end
    
    % Options 1 and 2: Modifying a specific link
    if choice == 1 || choice == 2
        disp(' ');
        
        % DYNAMIC PROMPT: Now shows the actual number of nodes
        nodeA = input(['Enter the first router of the link (Node A, 1-', num2str(numNodes), '): ']);
        nodeB = input(['Enter the second router of the link (Node B, 1-', num2str(numNodes), '): ']);
        
        % DYNAMIC VALIDATION: Checks against numNodes instead of 10
        if nodeA < 1 || nodeA > numNodes || nodeB < 1 || nodeB > numNodes || nodeA == nodeB
            disp('ERROR: Invalid routers entered. Please try again.');
            continue; 
        end
        
        edgeIdx = findedge(G, nodeA, nodeB);
        if edgeIdx == 0
            disp('ERROR: There is no direct link between these routers. Try again.');
            continue;
        end
        
        if choice == 1
            newWeight = input('Enter the new high traffic cost (e.g., 50, 100): ');
            statusMsg = 'CONGESTION DETECTED';
            lineStyle = '-';
            edgeLabel = num2str(newWeight);
        elseif choice == 2
            newWeight = inf; 
            statusMsg = 'CRITICAL LINK FAILURE';
            lineStyle = '--';
            edgeLabel = 'Inf'; 
        end
        
        disp(['Processing: ', statusMsg, ' on link R', num2str(nodeA), '-R', num2str(nodeB), '...']);
        
        costMatrix(nodeA, nodeB) = newWeight;
        costMatrix(nodeB, nodeA) = newWeight;
        G.Edges.Weight(edgeIdx) = newWeight;
        
        tic; 
        [newPath, newCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);
        elapsedTime = toc; 
        convergenceTimeMs = elapsedTime * 1000;
        
        p.EdgeColor = [0 0.4470 0.7410];
        p.LineWidth = 1;
        p.LineStyle = '-';
        labeledge(p, edgeIdx, edgeLabel);
        highlight(p, nodeA, nodeB, 'EdgeColor', 'r', 'LineWidth', 4, 'LineStyle', lineStyle);
        
        if isempty(newPath) || newCost == inf
            disp('NETWORK ISOLATED: No alternate paths available to the destination.');
            title('Network Failure. Destination Unreachable.');
        else
            highlight(p, newPath, 'EdgeColor', 'g', 'LineWidth', 3);
            title([statusMsg, ' - Self-Healed. Path Cost: ', num2str(newCost)]);
            
            disp('Success! Traffic Diverted.');
            disp(['New optimal path: ', num2str(newPath)]);
            disp(['New total path cost: ', num2str(newCost)]);
            
            pathBWs = [];
            for i = 1:(length(newPath)-1)
                pathBWs = [pathBWs, bwMatrix(newPath(i), newPath(i+1))];
            end
            fprintf('Path Bottleneck Capacity: %d Mbps\n', min(pathBWs));
            fprintf('Algorithm Convergence Time: %.4f milliseconds\n', convergenceTimeMs);
        end
        drawnow; 
        
    % Option 3: User wants to test a different start/end pair
    elseif choice == 3
        disp(' ');
        sourceNode = input(['Enter new Source Node (1-', num2str(numNodes), '): ']);
        destNode = input(['Enter new Destination Node (1-', num2str(numNodes), '): ']);
        
        % Validate Option 3 inputs
        if sourceNode < 1 || sourceNode > numNodes || destNode < 1 || destNode > numNodes
            disp('ERROR: Invalid routers entered. Please try again.');
            continue;
        end
        
        tic;
        [newPath, newCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);
        elapsedTime = toc;
        convergenceTimeMs = elapsedTime * 1000;
        
        p.EdgeColor = [0 0.4470 0.7410]; p.LineWidth = 1; p.LineStyle = '-';
        
        if isempty(newPath) || newCost == inf
            disp('NETWORK ISOLATED: Destination Unreachable.');
            title('Destination Unreachable.');
        else
            highlight(p, newPath, 'EdgeColor', 'g', 'LineWidth', 3);
            title(['Path changed: R', num2str(sourceNode), ' to R', num2str(destNode), ' | Cost: ', num2str(newCost)]);
            disp(['New optimal path: ', num2str(newPath)]);
            disp(['Total path cost: ', num2str(newCost)]);
            fprintf('Algorithm Convergence Time: %.4f milliseconds\n', convergenceTimeMs);
        end
        drawnow;
        
    % Option 4: Full router hardware crash
    elseif choice == 4
        disp(' ');
        fNode = input(['Enter Router to CRASH (1-', num2str(numNodes), '): ']);
        
        if fNode < 1 || fNode > numNodes
            disp('ERROR: Invalid router entered. Please try again.');
            continue;
        end
        
        costMatrix(fNode, :) = inf; 
        costMatrix(:, fNode) = inf;
        
        % DYNAMIC ARRAY SIZING: Uses numNodes instead of 10
        currentSizes = p.MarkerSize;
        if isscalar(currentSizes)
            currentSizes = repmat(currentSizes, [1, numNodes]);
        end
        currentSizes(fNode) = 15; 
        p.MarkerSize = currentSizes;
        
        newColors = p.NodeColor;
        if size(newColors, 1) == 1
            newColors = repmat(newColors, [numNodes, 1]);
        end
        newColors(fNode, :) = [1 0 0]; 
        p.NodeColor = newColors;
        
        edgesToHide = outedges(G, fNode); 
        G.Edges.Weight(edgesToHide) = inf;
        highlight(p, 'Edges', edgesToHide, 'EdgeColor', 'r', 'LineStyle', '--');
        
        disp(['SYSTEM ALERT: Router R', num2str(fNode), ' has crashed.']);
        
        tic;
        [newPath, newCost] = customDijkstraPQ(costMatrix, sourceNode, destNode);
        elapsedTime = toc;
        convergenceTimeMs = elapsedTime * 1000;
        
        p.EdgeColor = [0 0.4470 0.7410];
        highlight(p, 'Edges', edgesToHide, 'EdgeColor', 'r', 'LineStyle', '--'); 
        
        if isempty(newPath) || newCost == inf
            disp('NETWORK ISOLATED: Destination Unreachable.');
            title('Critical Failure: Network Isolated.');
        else
            highlight(p, newPath, 'EdgeColor', 'g', 'LineWidth', 3);
            title(['Self-Healed after R', num2str(fNode), ' Crash. Cost: ', num2str(newCost)]);
            disp('Success! Traffic Diverted around crashed node.');
            disp(['New optimal path: ', num2str(newPath)]);
            
            pathBWs = [];
            for i = 1:(length(newPath)-1)
                pathBWs = [pathBWs, bwMatrix(newPath(i), newPath(i+1))];
            end
            fprintf('Path Bottleneck Capacity: %d Mbps\n', min(pathBWs));
            fprintf('Algorithm Convergence Time: %.4f milliseconds\n', convergenceTimeMs);
        end
        drawnow;
        
    else
        disp('Invalid choice. Please type 0, 1, 2, 3, or 4 and press Enter.');
    end
end
