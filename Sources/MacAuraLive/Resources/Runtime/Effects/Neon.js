class NeonEffect {
    constructor(parameters = {}) {
        this.type = 'neon';
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
        this.t += dt * speed * 2.0;
    }

    render(ctx, w, h) {
        const color = this.parameters.color || '#ff007f';
        const intensity = parseFloat(this.parameters.intensity || 1.0);
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.globalAlpha = Math.min(1.0, 0.7 * intensity);

        const cy = h * 0.65;
        const spacing = 40;
        const offset = (this.t * 20) % spacing;

        // Draw horizontal grid lines
        for (let y = cy; y < h; y += spacing) {
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(w, y);
            ctx.stroke();
        }

        // Draw perspective vertical lines
        const cx = w / 2;
        for (let x = -w; x < w * 2; x += 60) {
            ctx.beginPath();
            ctx.moveTo(cx + (x - cx) * 0.1, cy);
            ctx.lineTo(x, h);
            ctx.stroke();
        }

        ctx.globalAlpha = 1.0;
    }
}

EffectRegistry.register('neon', NeonEffect);
