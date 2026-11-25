%% =====================================================================
%  Projet CSI 300 kW - Analyse spectrale (FFT) et THD
%  À lancer APRÈS la simulation : utilise les variables i_a et v_a
%  enregistrées par les blocs To Workspace (dans la variable out).
%  =====================================================================

N_per = 5;                         % nombre de périodes analysées (régime établi)
N     = round(N_per/(f_out*Ts));    % nombre d'échantillons correspondants

signaux = {squeeze(out.i_a.Data), squeeze(out.v_a.Data)};
noms    = {'Courant de charge i_a', 'Tension du filtre v_a'};
unites  = {'A', 'V'};

figure;
for s = 1:2
    x = signaux{s};
    x = x(end-N+1:end);             % on garde les N_per dernières périodes

    % FFT : amplitude crête de chaque composante
    X = fft(x)/N;
    A = 2*abs(X(1:floor(N/2)));
    A(1) = A(1)/2;                  % composante continue
    f = (0:floor(N/2)-1)'/(N*Ts);   % fréquences [Hz], pas de f_out/N_per

    % Fondamental (400 Hz) et THD
    k1  = N_per + 1;                % indice du 400 Hz
    A1  = A(k1);
    THD = sqrt(sum(A.^2) - A(1)^2 - A1^2)/A1*100;

    fprintf('%s : fondamental %.1f %s crête (%.1f %s eff.), THD = %.2f %%\n', ...
            noms{s}, A1, unites{s}, A1/sqrt(2), unites{s}, THD);

    % Spectre
    subplot(2,1,s);
    stem(f/1e3, A, 'Marker', 'none');
    set(gca, 'YScale', 'log');
    xlim([0 45]); ylim([1e-2 2*A1]);
    xlabel('Fréquence [kHz]'); ylabel(['Amplitude [' unites{s} ']']);
    title(sprintf('%s - THD = %.2f %%', noms{s}, THD));
    grid on;
end
