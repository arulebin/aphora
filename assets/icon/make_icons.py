TEAL='#0F6E6A'; CORAL='#E07A4F'
def bars(fill_side, fill_mid, cx=512, cy=481, s=0.85, W=50):
    out=[]
    xs=[-222,-148,-74,0,74,148,222]
    for x in xs:
        d=abs(x); L=150
        yc=-118+(222-d)*0.95      # tops/bottoms trace the two arms of a V
        X=cx+x*s; Y=cy+yc*s; h=L*s; w=W*s
        out.append(f'<rect x="{X-w/2:.1f}" y="{Y-h/2:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{w/2:.1f}" fill="{fill_mid if x==0 else fill_side}"/>')
    return ''.join(out)
# speech bubble: rounded body + tail at bottom-left
BUBBLE=('M392 222 H632 C736 222 812 298 812 402 V540 C812 644 736 720 632 720 H470 '
        'C440 720 420 728 396 744 L292 818 C266 836 238 826 240 794 L246 700 '
        'C226 672 212 616 212 540 V402 C212 298 288 222 392 222 Z')
GRAD='<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#14918A"/><stop offset="1" stop-color="#0B5552"/></linearGradient></defs>'
def mark(mono=False):
    if mono:
        return ('<mask id="m"><path d="%s" fill="white"/>%s</mask><rect width="1024" height="1024" fill="white" mask="url(#m)"/>'
                % (BUBBLE, bars('black','black')))
    return f'<path d="{BUBBLE}" fill="#FFFFFF"/>' + bars(TEAL, CORAL)
def svg(b): return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">{b}</svg>'
def scaled(inner, k):  # shrink around centre for the adaptive-icon safe zone
    t=512*(1-k); return f'<g transform="translate({t} {t}) scale({k})">{inner}</g>'
files={
 'icon': GRAD+'<rect width="1024" height="1024" fill="url(#g)"/>'+mark(),
 'bg':   GRAD+'<rect width="1024" height="1024" fill="url(#g)"/>',
 'fg':   scaled(mark(), 0.70),
 'mono': scaled(mark(True), 0.70),
 'mark': mark(),   # transparent, for in-app / README use
}
for n,b in files.items():
    open(n+'.svg','w').write(svg(b))
    open(n+'.html','w').write(f'<html><body style="margin:0;background:transparent">{svg(b)}</body></html>')
