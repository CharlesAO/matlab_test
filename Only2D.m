rename = 'only2d'
%% system matrix
A = [ 1,0,0;0,1,ST;0,0,1];
B = [0; ST^2/2; ST];
Q = B*B.';
% Measurment Covariance
R1 = STEREO_NOISE_S;
R2 = 0.01;
Q1 = 0.1;
%% init
Pinit = diag([100,100,100]);
lam0 = 1/Scale(1)/Z(1);
Xinit = [lam0 Z(1) VZ(1)];

P = zeros(3,3,length(t));
X = zeros(3,length(t));
KG = zeros(3,2,length(t));
P(:,:,1) = Pinit;
X(:,1) = Xinit;

    Xmax = zeros(3,length(t));
    Xmin = zeros(3,length(t));

%%
BF_ = BF;
for i=2:length(t)
    % Estimate
    Xhat = A * X(:,i-1);
    Phat = A*P(:,:,i-1)*A.' + Q*Q1;
    
    
    % Switch value
    if mDisp(i)== INFF
        R1_ = INFF*INFF; mD=0;
    else
        R1_ = R1; mD = mDisp(i);        
    end
    %H1 = [0 -BF_/Xhat(2)/Xhat(2) 0];
    %H1 = [0 -mD/Xhat(2) 0];
    %H1 = [0 -mD^2/BF_ 0];

    H2 = [Xhat(2) Xhat(1) 0];
    
    
    Kgain = Phat * H2.' / (H2*Phat*H2.'+R2/10000);
    % update 2
    Xnew =  Xhat + Kgain*(1/Scale(i) - Xhat(1) *Xhat(2));
    Pnew = (eye(3) - Kgain*H2)*Phat;

    
    X(:,i) = Xnew;
    P(:,:,i) = Pnew;
    KG(:,1,i)=Kgain;
    %KG(:,2,i)=Kgain2;
    if check_cinterval
        [Xmax_,Xmin_]=ConfidenceInterval(Xnew,Pnew);
        Xmax(:,i) = Xmax_;
        Xmin(:,i) = Xmin_;    
    end
end


%% figure
showResult