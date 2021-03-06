function [zWF,zWR] = GetDynamicImages(VideoName)
   opts.window = 20;
   opts.stride = 15;    
   % zWF is the forward dynamic sequence
   % zWR is the reverse dynamic sequence.
  [zWF,zWR] = getVideoImageSegmentsFull(VideoName,opts);        
    
end
 

function [zWF,zWR] = getVideoImageSegmentsFull(videoFullFIle,opts)
    xyloObj = VideoReader(videoFullFIle);       
    x = read(xyloObj);
    [w,h,~,len] = size(x);
    x = reshape(x,h*w*3,len);x =x';        
    Window_Size = opts.window; 
    stride = opts.stride;
%     %
%     len = Window_Size+1;
%     %
%     if len <30
        sStart = 1;
        sEnd = len;
%     else
%         sStart = 10;
%         sEnd = uint8(len/1.5);
%     end    
    segments = numel(sStart);    
    % pick only the middle segments
    if segments > 6
        sStart = sStart(round(segments/2)-3:round(segments/2)+2);
        sEnd = sEnd(round(segments/2)-3:round(segments/2)+2);
        segments = numel(sStart);    
    end
    zWF = zeros(w,h,3,segments,'uint8');zWR = zWF;
    for s = 1 : segments
        st = sStart(s);
        send = sEnd(s);
        [im_WF,im_WR] = processVideo(x(st:send,:),w,h);
        im_WF = linearMapping(im_WF);
        im_WR = linearMapping(im_WR);
        zWF(:,:,:,s)  = im_WF;
        zWR(:,:,:,s)  = im_WR;
    end    
end

function [im_WF,im_WR] = processVideo(x,w,h)
    [WF,WR] = genRankPoolImageRepresentation(single(x),10);    
     im_WF = reshape(WF,w,h,3);
     im_WR = reshape(WR,w,h,3);    
end

function [W_fow,W_rev] = genRankPoolImageRepresentation(data,CVAL)
    OneToN = [1:size(data,1)]';    
    Data = cumsum(data);
    Data = Data ./ repmat(OneToN,1,size(Data,2));
    W_fow = liblinearsvr(getNonLinearity(Data,'ssr'),CVAL,2); clear Data; 			
    order = 1:size(data,1);
    [~,order] = sort(order,'descend');
    data = data(order,:);
    Data = cumsum(data);
    Data = Data ./ repmat(OneToN,1,size(Data,2));
    W_rev = liblinearsvr(getNonLinearity(Data,'ssr'),CVAL,2); 			                  
end

function w = liblinearsvr(Data,C,normD)
    if normD == 2
        Data = normalizeL2(Data);
    end    
    if normD == 1
        Data = normalizeL1(Data);
    end    
    N = size(Data,1);
    Labels = [1:N]';
    model = train(double(Labels), sparse(double(Data)),sprintf('-c %1.6f -s 11 -q',C) );
    w = model.w';    
end

function Data = getNonLinearity(Data,nonLin)    
    switch nonLin            
        case 'ssr'
            Data = sign(Data).*sqrt(abs(Data));       
    end
end

function x = normalizeL2(x)
    v = sqrt(sum(x.*conj(x),2));
    v(find(v==0))=1;
    x=x./repmat(v,1,size(x,2));
end

function x = linearMapping(x)
    minV = min(x(:));
    maxV = max(x(:));
    x = x - minV;
    x = x ./ (maxV - minV);
    x = x .* 255;
    x = uint8(x);
end
