class AuroraEffect {
    constructor(parameters = {}) {
        this.type = 'aurora';
        this.baseParameters = { ...parameters };
        this.parameters = { ...parameters };
        this.t = 0;
    }

    resize(w, h) {
        this.width = w;
        this.height = h;
    }

    update(dt) {
        const speed = parseFloat(this.parameters.speed || 1.0);
        this.t += dt * speed * 0.5;
    }

    render(ctx, w, h) {
        const colorStart = this.parameters.colorStart || '#00f2fe';
        const colorEnd = this.parameters.colorEnd || '#4facfe';

        ctx.save();
        ctx.globalCompositeOperation = 'lighter';
        ctx.globalAlpha = parseFloat(this.parameters.opacity || 0.6);

        ctx.beginPath();
        for (let x = 0; x <= w; x += 15) {
            const y = h * 0.4 + Math.sin(x * 0.005 + this.t) * 90 + Math.cos(x * 0.012 - this.t) * 45;
            if (x === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
        }
        ctx.lineTo(w, h);
        ctx.lineTo(0, h);
        ctx.closePath();

        const grad = ctx.createLinearGradient(0, h * 0.2, 0, h);
        grad.addColorStop(0, colorStart);
        grad.addColorStop(1, colorEnd);
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.restore();
    }
}

EffectRegistry.register('aurora', AuroraEffect);
