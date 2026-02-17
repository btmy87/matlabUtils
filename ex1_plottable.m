% ex1_plottable

n = 1000;
data = table();
data.x = rand(n, 1);
data.y = data.x + 0.1*rand(n, 1);
data.z = data.x.^2 + 0.1*rand(n, 1);

figure;
plottable(data)

figure;
plottable(data, ["x", "y"], ["y", "z"]);

