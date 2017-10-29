
clear all
close all

set(0, 'DefaultLineLineWidth', 2) 

%% config
%true depth
% sampling time 
ST = 0.033 %33ms
END = 5.0 % 5sec simulation
STEREO_NOISE_S = 1; % 1px sigma for stereo disparity noise
MONO_NOISE_S = 1; % 1?? sigma for monocular distance estimation noise

%% make ground truth data 
t = (0:ST:END).'; %time 
len = size(t,1);
freq =0.4;
Z = 0.3 + 0.1*sin(2*pi*freq*t);% 300mm +- 100mm
VZ = 2*pi*freq*0.1*cos(2*pi*freq*t);
% Z= 0.8 - 0.1*t;% 300mm +- 100mm
% VZ = -0.1+0*t;

%% Noisy Observation 
BF = 0.065*400; % base line * focal length
StereoNoise = STEREO_NOISE_S * randn(length(t),1);
Disp = BF./Z + StereoNoise;


mDisp = Disp;
INFF = 1000000000;
mDisp(mDisp>BF/0.275) = INFF;

figure(1);
plot(t,Z)
title('GroundTruthDepth')
xlabel('time [s]')
ylabel('Object Depth [m]')
grid on;
figure(2)
plot(t,BF./mDisp,'r',t,Z,'b--')
title('Estimated Depth')
xlabel('time [s]')
ylabel('Depth [m]')
legend('measured','ground truth')
grid on;

%% Noisy Monocluar Obserbation
Z0 = 0.3 % the real distance template is taken
IMG_SIZE = 600/2% 300 times 300 pix template
MonoNoise = MONO_NOISE_S*randn(length(t),1); % sigma = 1px image noise 
Snoise = 2./(Z0./Z * IMG_SIZE).* MonoNoise;
Scale = Z0./Z + Snoise;
dScale =[1; Scale(2:length(t))./Scale(1:length(t)-1)];

figure(3);
plot(t,Scale,'r',t,Z0./Z,'b--')
title('Estimated Scaling')
xlabel('time [s]')
ylabel('Scaling')
legend('measured','ground truth')
grid on;

%% system matrix
A = [ 1,0,0;0,1,ST;0,0,1];
B = [0; ST^2/2; ST];
Q = B*B.';
% Measurment Covariance
R1 = STEREO_NOISE_S;
R2 = 5;

%% init
Pinit = diag([100,100,100]);
lam0 = 1/Z0;
Xinit = [lam0 Z(1) VZ(1)];

P = zeros(3,3,length(t));
X = zeros(3,length(t));
KG = zeros(3,2,length(t));
P(:,:,1) = Pinit;
X(:,1) = Xinit;

%%
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A*P(:,:,i-1)*A.' + Q;
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0;
    else
        R1_ = R1; mD = mDisp(i);        
    end
    %H1 = [0 -BF_/Xhat(2)/Xhat(2) 0];
    %H1 = [0 -mD/Xhat(2) 0];
    H1 = [0 -mD^2/BF_ 0];
    
    % KF gain
    Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
    % update
    Xhat2 =  Xhat + Kgain*(mDisp(i) - BF_/Xhat(2));
    Phat2 = (eye(3) - Kgain*H1)*Phat ;

    % KF gain2
%     if mDisp(i)== INFF
%         H2 = [0 Xhat2(1) 0];
%     else
%         H2 = [Xhat2(2) Xhat2(1) 0];
%     end
    H2 = [Xhat2(2) Xhat2(1) 0];
%     H2 = [0 1/Z0 0];
    
    Kgain2 = Phat2 * H2.' / (H2*Phat2*H2.'+R2);
    % update 2
    Xhat3 =  Xhat2 + Kgain2*(1/Scale(i) - Xhat2(1)*Xhat2(2));
    Phat3 = (eye(3) - Kgain2*H2)*Phat2;
    
    H3 = [0,ST*Xhat3(3)/Xhat3(2)/Xhat3(2),-ST/Xhat3(2)];
    Kgain3 = Phat3 * H3.' / (H3*Phat3*H3.'+R2*2);

    % update 3
    Xnew =  Xhat3 + Kgain3*( dScale(i) - 1 + Xhat3(3)/Xhat2(3)*ST);
    Pnew = (eye(3) - Kgain3*H3)*Phat3;
    
    
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
end


%% figure
figure(4)
plot(t,X(1,:).','r',[t(1) t(len)],[1/Z0 1/Z0],'b--')
xlabel('time [s]')
ylabel('inv depth [1/m]')
grid on
legend('EKF','GroundTruth');

figure(5)
plot(t,X(2,:).','r',t,BF./mDisp,'b--',t,Z,'g-.')
xlabel('time [s]')
ylabel('depth [m]')
grid on
legend('EKF','Stereo Only','Ground Truth');


EZ=BF./mDisp;
EVZ = (EZ(2:len) - EZ(1:len-1) )/ST;
figure(6)
plot(t,X(3,:).','r',t(1:len-1),EVZ,'b--',t,VZ,'g-.')
xlabel('time [s]')
ylabel('speed of depth [m/s]')
grid on
legend('EKF','Stereo Only','Ground Truth');

%%
figure(7)
plot(t,squeeze(KG(:,1,:)),'-',t,squeeze(KG(:,2,:)),'--')
xlabel('time [s]')
ylabel('speed of depth [m/s]')
grid on