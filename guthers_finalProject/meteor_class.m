%Class to be used in meteor_app.mlapp
%Written by Shane Guther - 991529673
%December 2022

classdef meteor_class

    methods
        function [layer, hb] = simulate_meteor(obj, m, d, a)
            % Declaring constants
            INITIAL_HEIGHT = 150000;       % The initial height in meters (m).
            INITIAL_VEL = 20;            % The initial velocity in km/s.
            TIME_STEP = 0.003;            % The size of each step in the simulation, in seconds (s)
            
            %Values are taked from user input in app GUI
            INITIAL_MASS = m;         %Mass of object in kg
            DENSITY = d;        %Mass of object in kg in m^3 may be assigned to different materials.
            ANGLE = a;  %Angle of arrival of meteor
    
            % Initialize variables used by multiple functions in simulation
            time = 0; %Real time
            height = 0; %current height of meteor in meters
            x2 = 0; %path of meteor on x axis
            y2 = 0; %path of meteor on y axis
            vel = 0;    %Current velocity of meteor in meters per second
            currMass = 0; %Current mass of meteor as it burns up
            fracMass = 100; %fractional percentage value of meteor mass as it burns up
            aoa = 0;    %angle of arrival or meteor 
            decl = 0;
            run = true;  
            
            %Create figure
            close all;
            h_fig = figure();
            h_fig.Position = [500 500 750 750];
    
            axis([0 INITIAL_HEIGHT 0 INITIAL_HEIGHT 0 INITIAL_HEIGHT]);
            grid on;

            % Labeling the x, y, z axes and set a plot title
            xlabel('Distance (m)', 'Color', 'r');      % red
            ylabel('Distance (m)', 'Color', [0 .6 0]); % dark green
            zlabel('Height (m)', 'Color', 'b');      % blue
            title('Meteor Simulation');
            view(-54, 8);
            x = -150000:2000:150000;
            y = -150000:2000:150000;
            

            startSim();     % Start the simulation
            startTime = datetime;  % For measuring time (this is not the simulation clock)
            
            [xr, yr] = meshgrid(x,y); %Rectangle mesh for atmosphere layers
            xLen = length(xr);
            yLen = length(yr);
            zr = zeros(xLen, yLen);
            
            %Creating each layer of the atmosphere
            ground = surface(xr, yr, zr);
            set(ground, 'FaceAlpha', 0.9,'FaceColor', '#0033cc', 'LineStyle', 'none');
            
            troposphere = surface(xr, yr, zr+12000);
            set(troposphere, 'FaceAlpha', 0.3, 'FaceColor', '#0099ff', 'LineStyle', 'none');
            
            stratosphere = surface(xr, yr, zr+50000);
            set(stratosphere, 'FaceAlpha', 0.3, 'FaceColor', '#6699ff', 'LineStyle', 'none');
            
            mesosphere = surface(xr, yr, zr+80000);
            set(mesosphere, 'FaceAlpha', 0.3, 'FaceColor', '#99ddff', 'LineStyle', 'none');
            
            %Labelling atmosphere levels
            text(50000, 0, 10, "ground");
            text(50000, 0, 12000, "troposphere (12 km)");
            text(50000, 0, 50000, "stratosphere (50 km)");
            text(50000, 0, 80000, "mesosphere (80 km)");

            %Creating meteor object
            r = 5000; %radius of sphere
            [xs,   ys,  zs] = sphere;
            XS = xs * r;
            YS = ys * r;
            ZS = zs * r;
            
            meteor = surface(XS, YS, ZS);
            set(meteor, 'FaceColor', '#ff8c1a', 'LineStyle', 'none');
            
            %Path of meteor line
           	trail = animatedline('Color', 'black', 'LineWidth',3);
            
            %Homogenous transform to move the meteor
            t = hgtransform;
            set(meteor, 'Parent', t);
            
            %lighting, shading and material effects
            lighting gouraud;
            %shading flat;
            material shiny;
            l = light;
            set(l,  'Position', [1000 1000 150000]);

            
            pause(2);
            
            % Main loop continues until velocity of meteor < 100
            while run
                burned = nextStep();    % Calculate meteor properties
                addpoints(trail, x2, y2+200, height); % update trail of meteor
                %translating and scaling meteor as it moves through the air
                M = eye(4);
                M = M * makehgtform('translate', [x2 y2 height]);
                M = M * makehgtform('scale', [fracMass fracMass fracMass]);
                set(t, 'Matrix', M);   % Update transformation matrix
                
                drawnow limitrate;
                
                
                if burned            % Display results and stop when meteor burns up
                    run = false;
                end
                
                if ~ishghandle(h_fig)   % Stop simulation if the user closes the figure window
                    run = false;
                end
                
            end

            %Updating values to return to the GUI based on where meteor
            %burned up
            layer = "";
            if height > 80000
                layer = "thermosphere";
            elseif height > 50000
                layer = "mesosphere";
            elseif height > 12000
                layer = "stratosphere";
            else
                layer = "troposphere";
            end
            
            %Adding annotation to visualization for where meteor burned up
            text(0, 50000, 120000, "Meteor burned up in the " + layer + " at " + height + " meters");
            %height burned to be passed to gui       
            hb = height;
            return;
            
            % Set initial conditions for the start of the simulation
            function startSim()
                currMass = INITIAL_MASS;
                height = INITIAL_HEIGHT;
                aoa = cos(ANGLE * (pi / 180));
                vel = INITIAL_VEL * 1000;
            end
            
            %update meteor properties each step of the main loop
            function burned = nextStep()
                burned = false;
                if height <= 0
                    return;
                end
                %Meteor calculations
                rho = 1.25 * exp(-height / 7000);
                decl = 1 * 1.2 * rho * vel * vel / ((currMass^.33333) * (DENSITY^.66667));
                ML = 0.15 * 1.2 * rho * vel * vel * vel * ((currMass / DENSITY)^.66667) / (2 * 3000000);
                dv = decl * TIME_STEP;
                dm = ML * TIME_STEP;
                time = time + TIME_STEP;
                height = height - vel * TIME_STEP * aoa;
                x2 = height;
                y2 = height;
                vel = vel - dv;
                currMass= currMass - dm;
                fracMass = currMass / INITIAL_MASS;
                dif = datetime - startTime;
                fprintf("%.3f s  \t%.3f s  \tHeight: %.2f m  \tVelocity: %.2f m/s \t Decel: %.2f \tMass Remaining %.2f percent \n", seconds(dif), time, height, vel, decl, fracMass*100);
                %if velocity falls below 100m/s, end simulation
                if (vel <= 100)
                    burned = true;
                end
            end
            
        end    
    end
end