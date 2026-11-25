%% =====================================================================
%  Projet CSI 300 kW - Paramètres du modèle (version minimale)
%  Pile à combustible -> Hacheur -> Inductance L_dc -> CSI
%                     -> Filtre C_f -> Charge R-L triphasée
%  MATLAB R2022b - lancer ce script avant chaque simulation
%  =====================================================================

clear; clc;

%% 1. HYPOTHÈSES =======================================================
P_nom   = 300e3;   % [W]  puissance nominale
V_pile  = 600;     % [V]  tension de la pile (supposée constante)
V_ac    = 400;     % [V]  tension composée efficace en sortie
f_out   = 400;     % [Hz] fréquence de sortie (aéronautique)
cos_phi = 0.9;     % [-]  facteur de puissance de la charge
f_dec   = 20e3;    % [Hz] fréquence de découpage
m_mod   = 0.9;     % [-]  indice de modulation : I_sortie_crête = m_mod*I_dc

ondul_Idc = 0.10;  % [-]  ondulation acceptée sur I_dc (10 %)
ondul_Vac = 0.05;  % [-]  ondulation acceptée sur la tension de sortie (5 %)

% 1.x Semi-conducteurs (valeurs communes aux switches et aux diodes)
R_on  = 1e-3;   % [Ohm] résistance à l'état passant
G_off = 1e-5;   % [S]   conductance à l'état bloqué (fuite)
V_f   = 0.8;    % [V]   tension de seuil des diodes

M_ref = 2*m_mod/sqrt(3);   % [-] amplitude des sinusoïdes de référence de la MLI

%% 2. CHARGE ÉQUIVALENTE (par phase, couplage étoile) ==================
V_ph = V_ac/sqrt(3);                        % [V]   tension simple efficace
I_ch = P_nom/(sqrt(3)*V_ac*cos_phi);        % [A]   courant de charge efficace
Z_ch = V_ph/I_ch;                           % [Ohm] impédance de la charge
R_ch = Z_ch*cos_phi;                        % [Ohm] résistance
L_ch = Z_ch*sin(acos(cos_phi))/(2*pi*f_out);% [H]   inductance

%% 3. POINT DE FONCTIONNEMENT CÔTÉ CONTINU =============================
I_dc = sqrt(2)*I_ch/m_mod;   % [A] courant continu (estimation prudente :
                             %     le filtre réduit en réalité le courant)
V_dc = P_nom/I_dc;           % [V] tension moyenne à l'entrée du CSI
D    = V_dc/V_pile;          % [-] rapport cyclique du hacheur

%% 4. COMPOSANTS PASSIFS ===============================================
% Inductance : limite l'ondulation du courant du hacheur
L_dc = V_pile*D*(1 - D)/(ondul_Idc*I_dc*f_dec);       % [H]
% Condensateurs : lissent le courant découpé en sortie du CSI
C_f  = I_dc/(4*ondul_Vac*sqrt(2)*V_ph*f_dec);         % [F] par phase

%% 5. SIMULATION =======================================================
Ts     = 1/(100*f_dec);   % [s] pas de calcul (100 points par période)
t_stop = 20/f_out;        % [s] 20 périodes de sortie (50 ms)

%% 5. RÉGULATION DU HACHEUR ============================================
R_eq = V_dc/I_dc;               % [Ohm] résistance qui remplace le CSI pour le test
f_bp = f_dec/10;                % [Hz]  rapidité visée pour la régulation
Kp   = L_dc*2*pi*f_bp/V_pile;   % [1/A] gain proportionnel du PI
Ki   = R_eq*2*pi*f_bp/V_pile;   % [1/(A.s)] gain intégral du PI

% Consigne de courant continu pour P_nom, en tenant compte du filtre
I_charge = V_ph/(R_ch + 1j*2*pi*f_out*L_ch);   % [A] courant de la charge (nombre complexe)
I_filtre = 1j*2*pi*f_out*C_f*V_ph;             % [A] courant des condensateurs
I_ref    = sqrt(2)*abs(I_charge + I_filtre)/m_mod;  % [A] consigne de I_dc

%% 6. RÉCAPITULATIF ====================================================
fprintf('Charge      : I = %.0f A eff, R = %.3f Ohm, L = %.1f uH\n', I_ch, R_ch, L_ch*1e6);
fprintf('Côté continu: I_dc = %.0f A, V_dc = %.0f V, D = %.2f\n', I_dc, V_dc, D);
fprintf('Composants  : L_dc = %.0f uH, C_f = %.0f uF par phase\n', L_dc*1e6, C_f*1e6);
