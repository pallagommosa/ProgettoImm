%function AffineMotion(u,v, prima)
    % Caricamento dei frame
    img1 = imread('images/cars1_01.jpg');
    img2 = imread('images/cars1_02.jpg');
    
    % Riduzione di 1/4 per fattori computazionali
    resize = 1/4;   
    img1 = imresize(img1, resize);
    img2 = imresize(img2, resize);
    
    % Trasformazione in scala di grigio e a valori double per poter essere forniti in input
    % al calcolatore di flusso ottico
   img1 = double(rgb2gray(img1));
   img2 = double(rgb2gray(img2));
    
    % Funzione che calcola flusso ottico tra 2 immagini e restituisce
    % derivata lungo le x,y e tempo pi� vettori di flusso ottico   
    
    [u,v] = Optflow(img1,img2); 

    
    iterazione=0; %Variabile che salva numero di iterazioni compiute su frame
    
    %Suddivisione di flusso ottico in regioni   
    if iterazione == 0 %&& prima == true
          [regioni, numregioni] = Image20x20Subdivider(u);
     end   
    
    %while iterazione <= 20 % Ciclare fino ad un numero euristico di iterazioni           


        affini = zeros(numregioni,7); %Matrice usata per salvare parametri affini e regione ad essi associata
        uStimato=u; %Vettore usato per salvare flusso ottico stimato lungo le x
        vStimato=v; %Vettore usato per salvare flusso stimato lungo le y
        %regioniScartateX=affiniX; %Matrice usata per salvare parametri affini scartati x e regione associata
        %regioniScartateY=affiniY; %Matrice usata per salvare parametri affini scartati y e regione associata

        threshold=1; %impostare soglia per eliminazione di valori troppo alti
        for i=1:numregioni
            [xt,yt]=find(regioni == i);
            [Axi, Ayi, uS, vS] = affine(u(regioni==i),v(regioni==i),xt,yt);
            uStimato(regioni == i)= uS;
            vStimato(regioni == i)= vS;
            if errorStima(u(regioni==i),v(regioni==i),uS,vS,threshold) == 1        
                  affini(i, 1:3) = Axi';  % Salvataggio dei parametri affini delle x
                  affini(i, 4:6) = Ayi'; % Salvataggio dei parametri affini della y
                  affini(i,7) = i; % Salvataggio della regione a cui sono associati 
            end
            %else
                  %regioniScartateX(i,1:3)=Axi'; % Salvataggio dei parametri affini delle x
                  %regioniScartateX(i,4)=i; % Salvataggio della regione          
                  %regioniScartateY(i,1:3)=Ayi'; % Salvataggio dei parametri affini della y
                  %regioniScartateY(i,4)=i;  
                  %regioni(regioni == i)=0; %Regioni scartate vengono poste al valore 0
            %end

        end     


        %Eliminazione di valori affini che non hanno superato la soglia        
        affini((affini(:,7) ==0),:) = [];

        %Ripulitura vettori delle regioni scartati
        %regioniScartateX((regioniScartateX(:,4)==0),:)=[];
       % regioniScartateY((regioniScartateY(:,4)==0),:)=[];
       
       

        %Kmeans adattivo
        % Th rappresenta distanza massima tra centri(0.75)
        th=0.75;
        [cc]= kmean_adattivo(affini,th);
        
        %Assegnameno regioni a cluster pi� vicino
        [newRegioni,distanza] = assegnaCluster(u, v,cc,regioni);

        % Elimino pixel con errore troppo alto da regioni
        % th rappresenta errore massimo
        th=1;
        newRegioni = residualError(newRegioni,distanza,th);
        
        % Separo le regioni non connesse
        newRegioni_2 = separaRegioni(newRegioni);
        
        % Elimino regioni troppo piccole
        newRegioni_2 = filtroRegioni(newRegioni_2);
        
        
        subplot(2,2,1);
         imshow(img1,[]);
         title('Immagine partenza.'); 
        
        subplot(2,2,2);
         imshow(regioni,[]);
         title(['Prima kmeans, cluster= ', num2str(numel(unique(regioni))), '.']);
    
        subplot(2,2,3);
        imshow(newRegioni,[]);
        title(['Dopo kmeans, cluster= ', num2str(numel(unique(newRegioni))), '.']);
        
        subplot(2,2,4);
        imshow(newRegioni_2,[]);
        title(['Dopo separa regioni e filtro, cluster= ', num2str(numel(unique(newRegioni_2))), '.']);
 
    %end % Fine iterazioni singolo frame
%end