% PHASE 1: Build the Static Network (The Map)
costMatrix = [
     0,  15,   0,   0,  20,   0,   0,   0,   0,  50; 
    15,   0,  10,   0,   0,  25,   0,   0,   0,   0; 
     0,  10,   0,  12,   0,   0,  30,   0,   0,   0; 
     0,   0,  12,   0,  18,   0,   0,  15,   0,   0; 
    20,   0,   0,  18,   0,  10,   0,   0,  40,   0; 
     0,  25,   0,   0,  10,   0,  14,   0,   0,   0; 
     0,   0,  30,   0,   0,  14,   0,   8,   0,  22; 
     0,   0,   0,  15,   0,   0,   8,   0,  16,   0; 
     0,   0,   0,   0,  40,   0,   0,  16,   0,  10; 
    50,   0,   0,   0,   0,   0,  22,   0,  10,   0  
];

G = graph(costMatrix); 

figure; 

p = plot(G, 'Layout', 'force', 'NodeLabel', {'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8', 'R9', 'R10'});

p.MarkerSize = 8;
p.NodeColor = 'b'; 
title('Phase 1: 5-Node Network Topology');

labeledge(p, 1:numedges(G), G.Edges.Weight);
disp('Phase 1 Complete: Network plotted successfully.');

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
disp('==================================================');
disp('   INTERACTIVE NETWORK SIMULATION INITIALIZED');
disp('==================================================');

while true
    disp(' ');
    disp('Choose an action to test network resilience:');
    disp('1. Simulate Traffic Congestion (Increase Link Cost)');
    disp('2. Simulate Link Failure (Break a Link)');
    disp('0. Exit Simulation');
    
    choice = input('Enter your choice (0/1/2): ');
    
    if choice == 0
        disp('Exiting simulation... Have a Great Day!!');
        break;
    end
    
    if choice == 1 || choice == 2
        disp(' ');
        
        nodeA = input('Enter the first router of the link (Node A, 1-10): ');
        nodeB = input('Enter the second router of the link (Node B, 1-10): ');
        
        if nodeA < 1 || nodeA > 10 || nodeB < 1 || nodeB > 10 || nodeA == nodeB
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
            edgeLabel = '\infty';
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
            title('Phase 4: Network Failure. Destination Unreachable.');
        else
            highlight(p, newPath, 'EdgeColor', 'g', 'LineWidth', 3);
            title([statusMsg, ' - Self-Healed. New Path Cost: ', num2str(newCost)]);
            
            disp('Success! Traffic Diverted.');
            disp(['New optimal path: ', num2str(newPath)]);
            disp(['New total path cost: ', num2str(newCost)]);
            
            fprintf('Algorithm Convergence Time: %.4f milliseconds\n', convergenceTimeMs);
        end
        
        drawnow; 
        
    else
        disp('Invalid choice. Please type 0, 1, or 2 and press Enter.');
    end
end