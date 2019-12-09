classdef app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        Image2                 matlab.ui.control.Image
        VeuillezintroduirevotreimageLabel  matlab.ui.control.Label
        TraiterlimageButton    matlab.ui.control.Button
        ChargeruneimageButton  matlab.ui.control.Button
        x1EditFieldLabel       matlab.ui.control.Label
        x1EditField            matlab.ui.control.NumericEditField
        y1EditFieldLabel       matlab.ui.control.Label
        y1EditField            matlab.ui.control.NumericEditField
        x2Label                matlab.ui.control.Label
        x2EditField_2          matlab.ui.control.NumericEditField
        y2EditFieldLabel       matlab.ui.control.Label
        y2EditField            matlab.ui.control.NumericEditField
    end

    
    properties (Access = private)
        I = [] % Image
        I2 = []% Image scindée
        message = ""
        toutesLesLignes = []
    end
    
    methods (Access = private)
        
        function results = scinder_image(app)
            longueur = app.y2EditField.Value - app.x1EditField.Value;
            largeur = app.x2EditField_2.Value - app.y1EditField.Value;
            app.I2= imcrop(app.I, [app.x1EditField.Value app.y1EditField.Value longueur largeur]);
            figure(2);
            imshow(app.I2);
            title('Image scindée contenant du bruit');
        end
        
        function results = traitement(app)
            
            Icorrected = imtophat(app.I2,strel('disk',15));
            
            marker = imerode(Icorrected, strel('line',10,0));
            Iclean = imreconstruct(marker, Icorrected);
            
            BW2 = imbinarize(Iclean);
            
            %figure(5); 
            %imshowpair(Iclean,BW2,'montage');
            
            results = ocr(BW2,'TextLayout','Block');
            app.toutesLesLignes = strsplit(results.Text, "\n");            
            
            app.message = "";
            verifierPremiereLettre(app);
        end
        
        function results = verifierPremiereLettre(app)
            close all;

            testA = contains(app.toutesLesLignes(3), 'A');
            testQ = contains(app.toutesLesLignes(5), 'Q');
            testM = contains(app.toutesLesLignes(5), 'M');
            
	    testQw = contains(app.toutesLesLignes(2), '€');
            %testAw = contains(app.toutesLesLignes(2), 'A');
	    testEt = contains(app.toutesLesLignes(1), '&');

             if(testA || testQ || testM)
                 testHum = contains(app.toutesLesLignes(2), '§');
                 indexArobase = strfind(char(app.toutesLesLignes(2)), '@');
                if(testHum || (~isempty(indexArobase) && indexArobase < length(app.premiereLettre)/2))
                    app.message = "AZERTY Belge";
                else
                    app.message = "AZERTY Français";
                end   
             elseif (testQw || testEt)
                app.message = "QWERTY";
	     else 
		app.message = "inconnu";
            end   
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: TraiterlimageButton
        function TraiterlimageButtonPushed(app, event)
            close all;
        
            scinder_image(app);
            if size(app.I2)
                app.I2 = rgb2gray(app.I2);
            end
                
            traitement(app);   
            app.VeuillezintroduirevotreimageLabel.Text = app.message;
        end

        % Button pushed function: ChargeruneimageButton
        function ChargeruneimageButtonPushed(app, event)
            [file,~]=uigetfile({'*.jpg';'*.bmp';'*.gif';'*.tiff'}, 'Select file');
            if file
                app.Image2.ImageSource = file;
                app.I = imread(file);
                figure(1);
                imshow(app.I);
                title('Image originale');
                impixelinfo;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'UI Figure';

            % Create Image2
            app.Image2 = uiimage(app.UIFigure);
            app.Image2.Position = [277 111 329 338];

            % Create VeuillezintroduirevotreimageLabel
            app.VeuillezintroduirevotreimageLabel = uilabel(app.UIFigure);
            app.VeuillezintroduirevotreimageLabel.BackgroundColor = [1 0.4118 0.1608];
            app.VeuillezintroduirevotreimageLabel.FontSize = 16;
            app.VeuillezintroduirevotreimageLabel.FontWeight = 'bold';
            app.VeuillezintroduirevotreimageLabel.FontColor = [1 1 1];
            app.VeuillezintroduirevotreimageLabel.Position = [170 35 331 50];
            app.VeuillezintroduirevotreimageLabel.Text = 'Veuillez introduire votre image';

            % Create TraiterlimageButton
            app.TraiterlimageButton = uibutton(app.UIFigure, 'push');
            app.TraiterlimageButton.ButtonPushedFcn = createCallbackFcn(app, @TraiterlimageButtonPushed, true);
            app.TraiterlimageButton.BackgroundColor = [1 0.4118 0.1608];
            app.TraiterlimageButton.FontColor = [1 1 1];
            app.TraiterlimageButton.Position = [113 153 100 22];
            app.TraiterlimageButton.Text = 'Traiter l''image';

            % Create ChargeruneimageButton
            app.ChargeruneimageButton = uibutton(app.UIFigure, 'push');
            app.ChargeruneimageButton.ButtonPushedFcn = createCallbackFcn(app, @ChargeruneimageButtonPushed, true);
            app.ChargeruneimageButton.BackgroundColor = [1 0.4118 0.1608];
            app.ChargeruneimageButton.FontColor = [1 1 1];
            app.ChargeruneimageButton.Position = [103 212 119 22];
            app.ChargeruneimageButton.Text = 'Charger une image';

            % Create x1EditFieldLabel
            app.x1EditFieldLabel = uilabel(app.UIFigure);
            app.x1EditFieldLabel.HorizontalAlignment = 'right';
            app.x1EditFieldLabel.Position = [73 418 25 22];
            app.x1EditFieldLabel.Text = 'x1:';

            % Create x1EditField
            app.x1EditField = uieditfield(app.UIFigure, 'numeric');
            app.x1EditField.Limits = [0 Inf];
            app.x1EditField.Position = [113 418 100 22];

            % Create y1EditFieldLabel
            app.y1EditFieldLabel = uilabel(app.UIFigure);
            app.y1EditFieldLabel.HorizontalAlignment = 'right';
            app.y1EditFieldLabel.Position = [73 371 25 22];
            app.y1EditFieldLabel.Text = 'y1:';

            % Create y1EditField
            app.y1EditField = uieditfield(app.UIFigure, 'numeric');
            app.y1EditField.Limits = [0 Inf];
            app.y1EditField.Position = [113 371 100 22];

            % Create x2Label
            app.x2Label = uilabel(app.UIFigure);
            app.x2Label.HorizontalAlignment = 'right';
            app.x2Label.Position = [73 323 25 22];
            app.x2Label.Text = 'x2:';

            % Create x2EditField_2
            app.x2EditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.x2EditField_2.Limits = [0 Inf];
            app.x2EditField_2.Position = [113 323 100 22];

            % Create y2EditFieldLabel
            app.y2EditFieldLabel = uilabel(app.UIFigure);
            app.y2EditFieldLabel.HorizontalAlignment = 'right';
            app.y2EditFieldLabel.Position = [73 269 25 22];
            app.y2EditFieldLabel.Text = 'y2:';

            % Create y2EditField
            app.y2EditField = uieditfield(app.UIFigure, 'numeric');
            app.y2EditField.Limits = [0 Inf];
            app.y2EditField.Position = [113 269 100 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
