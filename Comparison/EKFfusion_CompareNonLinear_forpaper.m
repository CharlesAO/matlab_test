% this is newer version in Feb 6 th 2018
%
% X_prop : switch in both
% X_conv1 : switch in No stereo
% X_conv2 : switch in with stereo
% X_conv3 : no switch
%% system matrix
A = [ 1,0,0;0,1,ST;0,0,1];
B = [0; ST^2/2; ST];
% B = [0; 0; ST];
Q = B*B.';
% Measurment Covariance
R1 = STEREO_NOISE_S;
R2 = 0.01;
Q1 = 0.1;
%% init
Pinit = diag([10000,10000,10000]);
lam0 = 1/Scale(1)/Z(1);
Xinit = [lam0*0.6 Z(1)*0.9 VZ(1)*1.1];
% Xinit = [lam0 Z(1) -1];

% proposed
P = zeros(3,3,length(t));
X = zeros(3,length(t));
KG = zeros(3,2,length(t));
Poles = zeros(3,length(t));
P(:,:,1) = Pinit;
X(:,1) = Xinit;

    Xmax = zeros(3,length(t));
    Xmin = zeros(3,length(t));
 
%% Xprop
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A * P(:,:,i-1) * A.' + Q*Q1;
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0; R2_=R2/100;
        % Reduced System
        A_ = A(2:3,2:3);
        Phat_ = A_*P(2:3,2:3,i-1)*A_'+Q(2:3,2:3)*Q1; Phat_ = Phat(2:3,2:3);
        H2_ = [Xhat(1) 0];          H2 = [0 Xhat(1) 0];
        H1_ = [-mD^2/BF_ 0];       H1 = [0 -mD^2/BF_ 0];
        Kgain_ = Phat_ * H1_.' / (H1_*Phat_*H1_.'+R1_);
        Kgain2_ = Phat_ * H2_.' / (H2_*Phat_*H2_.'+R2_);
        Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
        Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);

        %Kgain = [0;Kgain_];
        Kgain2 = [0;Kgain2_];
        %   update
    Xnew =  Xhat + [Kgain2]*[(1/Scale(i) - Xhat(1)*Xhat(2))];
    Pnew = Phat;
    Pnew(2:3,2:3) = (eye(2) - [Kgain2_]*[H2_])*Phat_; 
%     Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;
    else
        R1_ = R1; mD = mDisp(i); R2_=R2/100;
        H2 = [Xhat(2) 0 0];
%          H2 = [Xhat(2) Xhat(1) 0];
        H1 = [0 -mD^2/BF_ 0];
        Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
        Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);
        %   update
    Xnew =  Xhat + [Kgain Kgain2]*[(mDisp(i) - BF_/Xhat(2));(1/Scale(i) - Xhat(1)*Xhat(2))];
    Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat; 
    end

    




    % update 2
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
    Poles(:,i) = eig(A-[Kgain Kgain2]*[H1;H2]*A);

    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
   
end

X_prop = X;
Pole_prop = Poles;

%% Xconv1
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A * P(:,:,i-1) * A.' + Q*Q1;
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0; R2_=R2;
%         H2 = [0 Xhat(1) 0];
         H2 = [Xhat(2) Xhat(1) 0];
    else
        R1_ = R1; mD = mDisp(i); R2_=R2;  
%         H2 = [Xhat(2) 0 0];        
         H2 = [Xhat(2) Xhat(1) 0];
    end

    
    H1 = [0 -mD^2/BF_ 0];
    
    % KF gain
    Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
    Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);

    % update
    Xnew =  Xhat + [Kgain Kgain2]*[(mDisp(i) - BF_/Xhat(2));(1/Scale(i) - Xhat(1)*Xhat(2))];
    Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;

    % update 2
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
    Poles(:,i) = eig(A-[Kgain Kgain2]*[H1;H2]*A);

    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
   
end

X_conv1 = X;
Pole_conv1 = Poles;


%% Xconv3

% choose pole
p_hz = -3*pi*2;
c_pole = [p_hz,p_hz/sqrt(2)+p_hz/sqrt(2)*1i,p_hz/sqrt(2)-p_hz/sqrt(2)*1i];
c_pole = [p_hz,p_hz/2 + p_hz/sqrt(3)*1i,p_hz/2 - p_hz/sqrt(3)*1i];
c_pole2 = [p_hz/sqrt(2) + p_hz/sqrt(2)*1i,p_hz/sqrt(2) - p_hz/sqrt(2)*1i];
pole = exp(c_pole*ST);
pole2 = exp(c_pole2*ST);

RX = 0.01;
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A * P(:,:,i-1) * A.' + Q*Q1;
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0; R2_=R2/100;
        H2 = [0 Xhat(1) 0];
        H2 = [Xhat(2) Xhat(1) 0];
    else
        R1_ = RX; mD = mDisp(i); R2_=R2;  
        H2 = [Xhat(2) 0 0];        
        H2 = [Xhat(2) Xhat(1) 0];
    end

    
    H1 = [0 1/BF_ 0];
    
    if mDisp(i)== INFF
        Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
        Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);          
        Kpp = place(A(2:3,2:3)',A(2:3,2:3)'*[H2(2:3)]',pole(2:3))';
        Kgain2 = [0;Kpp];
        Xnew =  Xhat + [Kgain Kgain2]*[(1/mDisp(i) - Xhat(2)/BF_);(1/Scale(i) - Xhat(1)*Xhat(2))];
        Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;
    else
        Kpp = place(A',A'*[H1;H2]',pole)';
        Kgain = Kpp(:,1);
        Kgain2 = Kpp(:,2);
        % update
        Xnew =  Xhat + [Kgain Kgain2]*[(1/mDisp(i) - Xhat(2)/BF_);(1/Scale(i) - Xhat(1)*Xhat(2))];
        Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;
    end


    % update 2
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
    Poles(:,i) = eig(A-[Kgain Kgain2]*[H1;H2]*A);

    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
   
end


X_conv3 = X;
Pole_conv3 = Poles;

%% Xconv1: Changed Prop
RX = 0.01;
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A * P(:,:,i-1) * A.' + Q*Q1;
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0; R2_=R2/100;
        H2 = [0 Xhat(1) 0];
%         H2 = [Xhat(2) Xhat(1) 0];
    else
        R1_ = RX; mD = mDisp(i); R2_=R2;  
        H2 = [Xhat(2) 0 0];        
%         H2 = [Xhat(2) Xhat(1) 0];
    end

    
    H1 = [0 1/BF_ 0];
    
    % KF gain
    Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
    Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);

    % update
    Xnew =  Xhat + [Kgain Kgain2]*[(1/mDisp(i) - Xhat(2)/BF_);(1/Scale(i) - Xhat(1)*Xhat(2))];
    Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;

    % update 2
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
    Poles(:,i) = eig(A-[Kgain Kgain2]*[H1;H2]*A);

    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
   
end


X_conv1_1 = X;
Pole_conv1_1 = Poles;
%% Xconv2
BF_ = BF;
mu = 1.2;eta = 1;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A * P(:,:,i-1) * A.' + Q*Q1;

    H2 = [Xhat(2) Xhat(1) 0];

    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0; R2_=R2/100;
        H1 = [0 -mD^2/BF_ 0];
        H2 = [0 Xhat(1) 0];
        R2_ = (mu*H2*Phat*H2'+eta*eye(1))/100;
    else
        R1_ = R1; mD = mDisp(i); R2_=R2;  
        H1 = [0 -mD^2/BF_ 0];
        R2_ = mu*H2*Phat*H2'+eta*eye(1);
        R1_ = mu*H1*Phat*H1'+eta*eye(1);
    end

    
    
    % KF gain
    Kgain = Phat * H1.' / (H1*Phat*H1.'+R1_);
    Kgain2 = Phat * H2.' / (H2*Phat*H2.'+R2_);

    % update
    Xnew =  Xhat + [Kgain Kgain2]*[(mDisp(i) - BF_/Xhat(2));(1/Scale(i) - Xhat(1)*Xhat(2))];
    Pnew = (eye(3) - [Kgain Kgain2]*[H1;H2])*Phat;

    % update 2
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    KG(:,2,i)=Kgain2;
    Poles(:,i) = eig(A-[Kgain Kgain2]*[H1;H2]*A);

    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
   
end

X_conv2 = X;
Pole_conv2 = Poles;

%%
rename = 'EKFcomp_Nonlinear_forpaper'
% rename = ['EKF_1change']
% % rename = ['EKF_prop']
% showResult
% showPole
showComp_forPaper