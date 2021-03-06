%% make ground truth data 
t = (0:ST:END).'; %time 
len = size(t,1);
freq =0.16;
phase = pi/2
% Z = 0.3 + 0.15*sin(2*pi*freq*t+pi/2);% 300mm +- 100mm
Z = 0.315 + 0.15*sin(2*pi*freq*t+phase);% 300mm +- 100mm
VZ = 2*pi*freq*0.15*cos(2*pi*freq*t+phase);
AZ = -2*pi*2*pi*freq*0.15*freq*sin(2*pi*freq*t+phase);
X = 1;
Cta = pi/4*t./max(t);

%% Template size and init condition
Z0 = 0.315 % the real distance template is taken
Wid = 0.2000; Hei = 0.1500;
f = 400;
hl = f*Hei./(Z-Wid/2*sin(Cta));
hr = f*Hei./(Z+Wid/2*sin(Cta));
h0 = f*Hei./(Z0);
% [hl,hr]=ImageObs(f,X,Z,Cta,Wid,Hei);
% h0 = ImageObs(f,X,Z0,0,Wid,Hei);


%% Monocular Obs
% noise
hl_ = hl+h0/100*randn(len,1);
hr_ = hr+h0/100*randn(len,1);

s_hat = 

Cta_hat = asin(f*Hei/Wid*(1./hr_-1./hl_));
figure(1)
plot(t,Cta,'r',t,Cta_hat,'b--')



%% Noisy Observation 
% BF = 0.065*400; % base line * focal length
% StereoNoise = STEREO_NOISE_S * randn(length(t),1);
% Disp = BF./Z + StereoNoise;
% Zlim = 0.4;
% 
% mDisp = Disp;
% INFF = 1000000000;
% mDisp(mDisp>BF/Zlim) = INFF;
% 
% figure(1);
% plot(t,Z)
% title('GroundTruthDepth')
% xlabel('time [s]')
% ylabel('Object Depth [m]')
% grid on;
% 
% %% Noisy Monocluar Obserbation
% MonoNoise = MONO_NOISE_S*randn(length(t),1); % sigma = 1px image noise 
% Snoise = 2./(Z0./Z * IMG_SIZE).* MonoNoise;
% Scale = Z0./Z + Snoise;
% dScale = [1; Scale(2:length(t))./Scale(1:length(t)-1)];
% 
% hfig=figure(2)
% plt = plot(t,Z,'b-.',t,BF./mDisp,'r',t,Z0./Scale,'m--')
% % setfigcolor(plt,'gby')
% title('Estimated Depth')
% xlabel('time [s]')
% ylabel('Depth [m]')
% xlim([0 END/2])
% legend('ground truth','3D measured','2D measured')
% grid on;
%     pfig = pubfig(hfig);
%     pfig.LegendLoc = 'best';
%     pfig.Dimension = [15 11];
%     expfig(['Estimated Depth'],'-pdf');
% 
% 
% hfig=figure(3);
% plot(t,Scale,'r',t,Z0./Z,'b--')
% title('Estimated Scaling')
% xlabel('time [s]')
% ylabel('Scaling')
% legend('measured','ground truth')
% grid on;
%     pfig = pubfig(hfig);
%     pfig.LegendLoc = 'best';
%     pfig.Dimension = [15 11];
%     expfig(['Estimated Scaling'],'-pdf');
