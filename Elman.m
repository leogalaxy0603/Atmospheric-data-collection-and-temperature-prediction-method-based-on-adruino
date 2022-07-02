%% initialization
clear
close all
clc
warning off

%% data read
Function_dataname='Dataset2'; % Dateset1=jena_climate_2009_2016; 
                              % Dateset2=202206029;
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


%% ��ͼ
figure
plot(output_test,'b-*','linewidth',1)
hold on
plot(test_simu0,'r-v','linewidth',1,'markerfacecolor','r')
legend('��ʵֵ','ELMANԤ��ֵ')
xlabel('�����������')
ylabel('ָ��ֵ')
title('ELMAN������Ԥ��ֵ����ʵֵ�Ա�ͼ')

figure
plot(error0,'rv-','markerfacecolor','r')
hold on
legend('ELMANԤ�����')
xlabel('�����������')
ylabel('Ԥ��ƫ��')
title('ELMAN������Ԥ��ֵ����ʵֵ���Ա�ͼ')

disp(' ')
disp('/////////////////////////////////')
disp('��ӡ������')
disp('�������     ʵ��ֵ      ELMANԤ��ֵ     ELMAN���')
for i=1:testNum
    disp([i output_test(i),test_simu0(i),error0(i)])
end

