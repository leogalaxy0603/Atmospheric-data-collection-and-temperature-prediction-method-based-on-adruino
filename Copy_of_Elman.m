%% ��ʼ��
clear
close all
clc
warning off

%% ���ݶ�ȡ
Function_dataname='Dataset1'; % Dateset1=glass1; Dateset2=ecoli3; Dateset3=vehicle3 
                              % Dateset4=newthyroid2; Dateset5=yeast1
data = Get_datasets(Function_dataname);
%  data=xlsread('����.xlsx','Sheet1','A1:N252'); %%ʹ��xlsread������ȡEXCEL�ж�Ӧ��Χ�����ݼ���

%�����������
input=data(:,1:end-1);    %data�ĵ�һ��-�����ڶ���Ϊ����ָ��
output=data(:,end);  %data�������һ��Ϊ�����ָ��ֵ

N=length(output);   %ȫ��������Ŀ
testNum=300;   %�趨����������Ŀ Ĭ��15
trainNum=N-testNum;    %����ѵ��������Ŀ

%% ����ѵ���������Լ�
input_train = input(1:trainNum,:)';
output_train =output(1:trainNum)';
input_test =input(trainNum+1:trainNum+testNum,:)';
output_test =output(trainNum+1:trainNum+testNum)';

%% ���ݹ�һ��
[inputn,inputps]=mapminmax(input_train,0,1);
[outputn,outputps]=mapminmax(output_train);
inputn_test=mapminmax('apply',input_test,inputps);

%% ��ȡ�����ڵ㡢�����ڵ����
inputnum=size(input,2);
outputnum=size(output,2);
disp('/////////////////////////////////')
disp('������ṹ...')
disp(['�����Ľڵ���Ϊ��',num2str(inputnum)])
disp(['�����Ľڵ���Ϊ��',num2str(outputnum)])
disp(' ')
disp('������ڵ��ȷ������...')

%ȷ��������ڵ����
%���þ��鹫ʽhiddennum=sqrt(m+n)+a��mΪ�����ڵ������nΪ�����ڵ������aһ��ȡΪ1-10֮�������
MSE=1e+5; %��ʼ����С���
for hiddennum=fix(sqrt(inputnum+outputnum))+1:fix(sqrt(inputnum+outputnum))+10
    
    %��������
    net=newelm(inputn,outputn,hiddennum);
    % �������
    net.trainParam.epochs=1000;         % ѵ������
    net.trainParam.lr=0.01;                   % ѧϰ����
    net.trainParam.goal=0.000001;        % ѵ��Ŀ����С���
    % ����ѵ��
    net=train(net,inputn,outputn);
    an0=sim(net,inputn);  %������
    mse0=mse(outputn,an0);  %����ľ������
    disp(['������ڵ���Ϊ',num2str(hiddennum),'ʱ��ѵ�����ľ������Ϊ��',num2str(mse0)])
    
    %������ѵ�������ڵ�
    if mse0<MSE
        MSE=mse0;
        hiddennum_best=hiddennum;
    end
end
disp(['��ѵ�������ڵ���Ϊ��',num2str(hiddennum_best),'����Ӧ�ľ������Ϊ��',num2str(MSE)])

%% �������������ڵ��ELMAN������
disp(' ')
disp('��׼��ELMAN�����磺')
net0=newelm(inputn,outputn,hiddennum_best,{'tansig','purelin'},'trainlm');% ����ģ��

%�����������
net0.trainParam.epochs=1000;         % ѵ����������������Ϊ1000��
net0.trainParam.lr=0.01;                   % ѧϰ���ʣ���������Ϊ0.01
net0.trainParam.goal=0.00001;                    % ѵ��Ŀ����С����������Ϊ0.0001
net0.trainParam.show=25;                % ��ʾƵ�ʣ���������Ϊÿѵ��25����ʾһ��
net0.trainParam.mc=0.01;                 % ��������
net0.trainParam.min_grad=1e-6;       % ��С�����ݶ�
net0.trainParam.max_fail=6;               % ���ʧ�ܴ���

%��ʼѵ��
net0=train(net0,inputn,outputn);

%Ԥ��
an0=sim(net0,inputn_test); %��ѵ���õ�ģ�ͽ��з���

%Ԥ��������һ����������
test_simu0=mapminmax('reverse',an0,outputps); %�ѷ���õ������ݻ�ԭΪԭʼ��������
%���ָ��
[mae0,mse0,rmse0,mape0,error0,errorPercent0]=calc_error(output_test,test_simu0);

%% �����Ż��㷨Ѱ����Ȩֵ��ֵ
disp(' ')
disp('WOA�Ż�ELMAN�����磺')
net=newelm(inputn,outputn,hiddennum_best,{'tansig','purelin'},'trainlm');% ����ģ��

%�����������
net.trainParam.epochs=1000;         % ѵ����������������Ϊ1000��
net.trainParam.lr=0.01;                   % ѧϰ���ʣ���������Ϊ0.01
net.trainParam.goal=0.00001;                    % ѵ��Ŀ����С����������Ϊ0.0001
net.trainParam.show=25;                % ��ʾƵ�ʣ���������Ϊÿѵ��25����ʾһ��
net.trainParam.mc=0.01;                 % ��������
net.trainParam.min_grad=1e-6;       % ��С�����ݶ�
net.trainParam.max_fail=6;               % ���ʧ�ܴ���

%% ��ʼ��WOA����
popsize=30;   %��ʼ��Ⱥ��ģ
maxgen=50;   %����������
dim=inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best+hiddennum_best*outputnum+outputnum;    %�Ա�������
lb=repmat(-3,1,dim);    %�Ա�������
ub=repmat(3,1,dim);   %�Ա�������
%��ʼ��λ���������쵼�ߵ÷�
Leader_pos=zeros(1,dim);
Leader_score=10^20;   
Net=net;

%% ��ʼ����Ⱥ
for i=1:dim
    ub_i=ub(i);
    lb_i=lb(i);
   Positions(:,i)=rand(popsize,1).*(ub_i-lb_i)+lb_i;
end
curve=zeros(maxgen,1);%��ʼ����������
%
% ѭ����ʼ
h0 = waitbar(0,'����','Name','WOA optimization...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h0,'canceling',0);
%}
for t=1:maxgen
    for i=1:size(Positions,1)%��ÿ������һ��һ������Ƿ�Խ��
        %��ÿ������һ��һ������Ƿ�Խ��
        % ���س��������ռ�߽����������
        Flag4ub=Positions(i,:)>ub;
        Flag4lb=Positions(i,:)<lb;
        Positions(i,:)=(Positions(i,:).*(~(Flag4ub+Flag4lb)))+ub.*Flag4ub+lb.*Flag4lb;%�������ֵ�����ó����ֵ��������Сֵ�����ó���Сֵ
        %Ŀ�꺯��ֵ�ļ���
        [fit(i),NET]=fitness(Positions(i,:),inputnum,hiddennum_best,outputnum,net,inputn,outputn,output_train,inputn_test,outputps,output_test);
        
        % �����쵼��λ��
        if fit(i)<Leader_score
            Leader_score=fit(i);
            Leader_pos=Positions(i,:);
            Net=NET;
        end
    end
    
    a=2-t*((2)/maxgen);
    a2=-1+t*((-1)/maxgen);
    %��������
    for i=1:size(Positions,1)
        r1=rand();r2=rand();
        A=2*a*r1-a;
        C=2*r2;
       
        b=1;
        l=(a2-1)*rand+1;
        
        p = rand();
        
        for j=1:size(Positions,2)%��ÿһ������ض�ά�Ƚ���ѭ������
            %������Χ����
            if p<0.5
                if abs(A)>=1
                    rand_leader_index = floor(popsize*rand()+1);%floor�� X ��ÿ��Ԫ���������뵽С�ڻ���ڸ�Ԫ�ص���ӽ�����
                    X_rand = Positions(rand_leader_index, :);
                    D_X_rand=abs(C*X_rand(j)-Positions(i,j));
                    Positions(i,j)=X_rand(j)-A*D_X_rand;
                elseif abs(A)<1
                    D_Leader=abs(C*Leader_pos(j)-Positions(i,j));
                    Positions(i,j)=Leader_pos(j)-A*D_Leader;
                end
                %��������λ��
            elseif p>=0.5
                distance2Leader=abs(Leader_pos(j)-Positions(i,j));
                Positions(i,j)=distance2Leader*exp(b.*l).*cos(l.*2*pi)+Leader_pos(j);
            end
        end
    end
    curve(t)=Leader_score;
    waitbar(t/maxgen,h0,[num2str(t/maxgen*100),'%'])
    if getappdata(h0,'canceling')
        break
    end
end
delete(h0)

%% ���ƽ�������
figure
plot(curve,'r-','linewidth',2)
xlabel('��������')
ylabel('�������')
legend('�����Ӧ��')
title('WOA��������')
w1=Leader_pos(1:inputnum*hiddennum_best);  %����㵽�������ȨֵԪ��
w2=Leader_pos(inputnum*hiddennum_best+1:inputnum*hiddennum_best+hiddennum_best*hiddennum_best);  %�нӲ㵽�������Ȩֵ
B1=Leader_pos(inputnum*hiddennum_best+hiddennum_best*hiddennum_best+1:inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best);  %�����㵽������ȨֵԪ��
w3=Leader_pos(inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best+1:inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best+hiddennum_best*outputnum);  %������ĸ���Ԫ��ֵԪ��
B2=Leader_pos(inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best+hiddennum_best*outputnum+1:inputnum*hiddennum_best+hiddennum_best*hiddennum_best+hiddennum_best+hiddennum_best*outputnum+outputnum);   %�����ĸ���Ԫ��ֵԪ��

%�����ع�
net.iw{1,1}=reshape(w1,hiddennum_best,inputnum);   %����㵽�������Ȩֵ
net.lw{1,1}=reshape(w2,hiddennum_best,hiddennum_best);   %�нӲ㵽�������Ȩֵ
net.lw{2,1}=reshape(w3,outputnum,hiddennum_best);   %�����㵽������Ȩֵ����
net.b{1}=reshape(B1,hiddennum_best,1);    %������ĸ���Ԫ��ֵ
net.b{2}=B2;    %�����ĸ���Ԫ��ֵ

%�Ż����������
net=Net;

%% �Ż�������������
an1=sim(net,inputn_test);
test_simu1=mapminmax('reverse',an1,outputps); %�ѷ���õ������ݻ�ԭΪԭʼ��������
%���ָ��
[mae1,mse1,rmse1,mape1,error1,errorPercent1]=calc_error(output_test,test_simu1);


%% ��ͼ
figure
plot(output_test,'b-*','linewidth',1)
hold on
plot(test_simu0,'r-v','linewidth',1,'markerfacecolor','r')
hold on
plot(test_simu1,'k-o','linewidth',1,'markerfacecolor','k')
legend('��ʵֵ','ELMANԤ��ֵ','WOA-ELMANԤ��ֵ')
xlabel('�����������')
ylabel('ָ��ֵ')
title('WOA�Ż�ǰ���ELMAN������Ԥ��ֵ����ʵֵ�Ա�ͼ')

figure
plot(error0,'rv-','markerfacecolor','r')
hold on
plot(error1,'ko-','markerfacecolor','k')
legend('ELMANԤ�����','WOA-ELMANԤ�����')
xlabel('�����������')
ylabel('Ԥ��ƫ��')
title('WOA�Ż�ǰ���ELMAN������Ԥ��ֵ����ʵֵ���Ա�ͼ')

disp(' ')
disp('/////////////////////////////////')
disp('��ӡ������')
disp('�������     ʵ��ֵ      ELMANԤ��ֵ  WOA-ELMANֵ   ELMAN���   WOA-ELMAN���')
for i=1:testNum
    disp([i output_test(i),test_simu0(i),test_simu1(i),error0(i),error1(i)])
end

